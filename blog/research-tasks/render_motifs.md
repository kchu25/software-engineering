@def title = "Comprehensive Refactoring Solution for patterns"
@def published = "21 October 2025"
@def tags = ["julia"]

# Comprehensive Refactoring Solution for patterns

## Overview

You have a Mustache.jl template system generating interactive HTML pages for genomic motif visualization. The current architecture has server dependencies, memory issues, and maintainability problems. Here's a complete refactoring solution.

---

## Architecture Philosophy

**BUILD-TIME PROCESSING → SELF-CONTAINED HTML**

Everything should be processed in Julia and baked into the HTML. No runtime fetching, no external JSON files.

---

## Refactored File Structure

```
output/
├── index1.html          # Self-contained, no server needed
├── index2.html
├── index3.html
└── readme/
    └── readme.html
```

Each HTML file contains:
- All data inline (no external JSON)
- All modular JavaScript inline
- All highlighted sequences pre-rendered
- CSS inline or as data URL

---

## Part 1: Julia-Side Refactoring

### New Data Preparation Function

```julia
"""
Pre-process all data for a single page
Returns a dictionary ready for Mustache rendering
"""
function prepare_page_data(j::Int, mode_count::Int, protein_name::String)
    # 1. Load and structure motif data
    modes = []
    for i in 1:mode_count
        mode_data = load_mode_data(i, j)
        
        # Convert images to data URLs or keep as relative paths
        images = mode_data.images
        labels = mode_data.labels
        texts = mode_data.texts
        
        # Pre-render the slider HTML for each combination
        combinations = []
        for (idx, (img, label, text_array)) in enumerate(zip(images, labels, texts))
            push!(combinations, Dict(
                "index" => idx - 1,  # 0-based for JS
                "image" => img,
                "label" => label,
                "texts" => text_array,
                "is_last" => idx == length(images)
            ))
        end
        
        push!(modes, Dict(
            "mode_index" => i,
            "combinations" => combinations,
            "max_index" => length(images) - 1,
            "has_slider" => length(images) > 1,
            "first_image" => images[1],
            "first_label" => labels[1],
            "first_texts" => texts[1]
        ))
    end
    
    # 2. Pre-render highlighted sequences
    highlighted_sequences = prepare_highlighted_sequences(j)
    
    # 3. Return complete data structure
    return Dict(
        "j" => j,
        "protein_name" => protein_name,
        "mode_count" => mode_count,
        "upto" => 6,  # total pages
        "modes" => modes,
        "highlighted_sequences" => highlighted_sequences
    )
end

"""
Pre-render all highlighted sequences as HTML
This eliminates runtime FASTA parsing
"""
function prepare_highlighted_sequences(j::Int)
    sequences_html = Dict[]
    
    # Get all CSV files for this page
    csv_files = get_csv_files_for_page(j)
    
    for csv_file in csv_files
        # Load sequences and highlights
        fasta_files = get_fasta_files_for_csv(csv_file)
        sequences = load_all_sequences(fasta_files)
        highlights = load_highlights(csv_file)
        
        # Generate highlighted HTML
        html = generate_highlighted_html(sequences, highlights)
        
        push!(sequences_html, Dict(
            "csv_id" => basename(csv_file),
            "html_content" => html
        ))
    end
    
    return sequences_html
end

"""
Generate highlighted sequence HTML
"""
function generate_highlighted_html(sequences, highlights)
    io = IOBuffer()
    
    # Group highlights by sequence index
    highlights_by_seq = group_by_sequence(highlights)
    
    for (seq_idx, seq) in enumerate(sequences)
        seq_highlights = get(highlights_by_seq, seq_idx, [])
        
        write(io, "<div class=\"header\">$(escape_html(seq.header))</div>\n")
        write(io, "<div class=\"sequence\">")
        write(io, highlight_sequence(seq.sequence, seq_highlights))
        write(io, "</div>\n")
    end
    
    return String(take!(io))
end

"""
Apply highlights to a sequence string
"""
function highlight_sequence(sequence::String, highlights)
    # Sort and merge overlapping highlights
    merged = merge_highlights(highlights)
    
    io = IOBuffer()
    last_pos = 1
    
    for h in merged
        # Write unhighlighted part
        if h.start > last_pos
            write(io, sequence[last_pos:h.start-1])
        end
        
        # Write highlighted part
        css_class = h.iscomp == 1 ? "highlight-comp" : "highlight"
        write(io, "<span class=\"$css_class\">")
        write(io, sequence[h.start:h.end])
        write(io, "</span>")
        
        last_pos = h.end + 1
    end
    
    # Write remaining sequence
    if last_pos <= length(sequence)
        write(io, sequence[last_pos:end])
    end
    
    return String(take!(io))
end

function merge_highlights(highlights)
    # Sort by start position
    sorted = sort(highlights, by = h -> h.start)
    
    merged = []
    for h in sorted
        if isempty(merged) || merged[end].end < h.start
            push!(merged, h)
        else
            # Merge overlapping
            merged[end] = (
                start = merged[end].start,
                end = max(merged[end].end, h.end),
                iscomp = h.iscomp  # Keep last value
            )
        end
    end
    
    return merged
end
```

---

## Part 2: New Modular JavaScript Template

### Inline JavaScript Structure

```javascript
// Create a single, modular script template
script_template_modular = mt"""
<script>
(function() {
    'use strict';
    
    // ============= CONFIGURATION =============
    const CONFIG = {
        currentPage: {{:j}},
        totalPages: {{:upto}},
        modeCount: {{:mode_count}}
    };
    
    // ============= DATA (INLINE) =============
    const DATA = {
        modes: [
            {{#:modes}}
            {
                index: {{:mode_index}},
                hasSlider: {{:has_slider}},
                maxIndex: {{:max_index}},
                combinations: [
                    {{#:combinations}}
                    {
                        index: {{:index}},
                        image: '{{{:image}}}',
                        label: '{{{:label}}}',
                        texts: [
                            {{#:texts}}
                            '{{{.}}}'{{^.[end]}},{{/.[end]}}
                            {{/:texts}}
                        ]
                    }{{^:is_last}},{{/:is_last}}
                    {{/:combinations}}
                ]
            }{{^.[end]}},{{/.[end]}}
            {{/:modes}}
        ],
        highlightedSequences: {
            {{#:highlighted_sequences}}
            '{{:csv_id}}': `{{{:html_content}}}`{{^.[end]}},{{/.[end]}}
            {{/:highlighted_sequences}}
        }
    };
    
    // ============= UTILITIES =============
    const $ = id => document.getElementById(id);
    const $$ = selector => document.querySelectorAll(selector);
    
    // ============= NAVIGATION MODULE =============
    const Navigation = {
        pageLabels: [
            'Singleton motifs',
            'Paired motifs',
            'Triplet motifs',
            'Quadruplet motifs',
            'Quintuplet motifs',
            'Sextuplet motifs'
        ],
        
        init() {
            const links = [];
            
            for (let i = 1; i <= CONFIG.totalPages; i++) {
                const href = `index${i}.html`;
                const label = this.pageLabels[i - 1];
                const isCurrent = i === CONFIG.currentPage;
                const className = isCurrent ? ' class="current"' : '';
                links.push(`<a href="${href}"${className}>${label}</a>`);
            }
            
            // Add readme link
            links.push(`<a href="../../../readme/readme.html">Readme</a>`);
            
            $('nav').innerHTML = links.join(' &nbsp&nbsp | &nbsp&nbsp ');
        }
    };
    
    // ============= SLIDER MODULE =============
    class MotifSlider {
        constructor(modeIndex, modeData) {
            this.modeIndex = modeIndex;
            this.data = modeData;
            this.elements = this.getElements();
            
            if (!modeData.hasSlider) {
                this.hideSlider();
            } else {
                this.attachEventListener();
            }
            
            this.setInitialState();
        }
        
        getElements() {
            return {
                slider: $(`valR${this.modeIndex}`),
                image: $(`img${this.modeIndex}`),
                label: $(`range${this.modeIndex}`),
                texts: Array.from({length: 6}, (_, i) => 
                    $(`text${this.modeIndex}_${i + 1}`))
            };
        }
        
        hideSlider() {
            if (this.elements.slider) {
                this.elements.slider.style.display = 'none';
            }
        }
        
        attachEventListener() {
            this.elements.slider?.addEventListener('input', (e) => {
                this.update(parseInt(e.target.value));
            });
        }
        
        setInitialState() {
            const combo = this.data.combinations[0];
            this.elements.label.textContent = combo.label;
            this.elements.image.src = combo.image;
            combo.texts.forEach((text, i) => {
                if (this.elements.texts[i]) {
                    this.elements.texts[i].innerHTML = text;
                }
            });
        }
        
        update(index) {
            const combo = this.data.combinations[index];
            const {image, label, texts} = this.elements;
            
            // Fade out
            image.style.opacity = 0;
            
            setTimeout(() => {
                label.textContent = combo.label;
                combo.texts.forEach((text, i) => {
                    if (texts[i]) {
                        texts[i].innerHTML = text;
                    }
                });
                image.src = combo.image;
                image.style.opacity = 1;
            }, 250);
        }
    }
    
    // ============= MODAL MODULE =============
    const Modal = {
        scrollPosition: 0,
        
        saveScrollPosition() {
            this.scrollPosition = window.pageYOffset || document.documentElement.scrollTop;
        },
        
        restoreScrollPosition() {
            window.scrollTo(0, this.scrollPosition);
        },
        
        openSequences(csvId) {
            this.saveScrollPosition();
            const html = DATA.highlightedSequences[csvId];
            $('highlightedSequences').innerHTML = html;
            $('highlightModal').style.display = 'block';
        },
        
        openImage(imageFile) {
            this.saveScrollPosition();
            const modalImage = $('modalImage1');
            modalImage.src = imageFile;
            
            modalImage.onload = function() {
                const modal = $('highlightModal_img_content');
                const imgWidth = modalImage.naturalWidth;
                modal.style.width = (imgWidth > 800 ? 800 : imgWidth) + 'px';
            };
            
            $('highlightModal_img').style.display = 'block';
        },
        
        openText(textContent) {
            this.saveScrollPosition();
            const modalText = $('modalText1');
            modalText.innerHTML = textContent;
            
            const modalContent = $('highlightModal_text_content');
            const width = Math.min(Math.max(textContent.length * 10, 200), 800);
            modalContent.style.width = width + 'px';
            
            $('highlightModal_text').style.display = 'flex';
        },
        
        openCluster(imageFile, textContent) {
            this.saveScrollPosition();
            $('modalImage').src = imageFile;
            $('modalText').innerHTML = textContent;
            $('highlightModal_cluster').style.display = 'block';
        },
        
        close(modalId) {
            $(modalId).style.display = 'none';
            this.restoreScrollPosition();
        },
        
        copyText() {
            const modalTextElement = $('modalText1');
            const originalText = modalTextElement.innerText;
            
            const textarea = document.createElement('textarea');
            textarea.value = originalText;
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
            
            modalTextElement.innerHTML = 'string copied successfully!';
            setTimeout(() => {
                modalTextElement.innerHTML = originalText;
            }, 1000);
        }
    };
    
    // ============= GLOBAL FUNCTIONS (for onclick handlers) =============
    window.openHighlightPage = (csvId) => Modal.openSequences(csvId);
    window.openHtmlWindowImg = (imageFile) => Modal.openImage(imageFile);
    window.openHtmlWindowText = (textContent) => Modal.openText(textContent);
    window.openHtmlWindow = (imageFile, textContent) => Modal.openCluster(imageFile, textContent);
    window.closeModal = () => Modal.close('highlightModal');
    window.closeModal_img = () => Modal.close('highlightModal_img');
    window.closeModal_text = () => Modal.close('highlightModal_text');
    window.closeModal_cluster = () => Modal.close('highlightModal_cluster');
    window.copyText = () => Modal.copyText();
    
    // ============= EVENT HANDLERS =============
    window.onclick = function(event) {
        const modals = ['highlightModal', 'highlightModal_cluster', 
                       'highlightModal_text', 'highlightModal_img'];
        modals.forEach(modalId => {
            const modal = $(modalId);
            if (event.target === modal) {
                Modal.close(modalId);
            }
        });
    };
    
    window.onkeydown = function(event) {
        if (event.key === 'Escape') {
            ['highlightModal', 'highlightModal_cluster', 
             'highlightModal_text', 'highlightModal_img'].forEach(modalId => {
                Modal.close(modalId);
            });
        }
    };
    
    // ============= INITIALIZATION =============
    document.addEventListener('DOMContentLoaded', () => {
        Navigation.init();
        
        DATA.modes.forEach(mode => {
            new MotifSlider(mode.index, mode);
        });
    });
    
})();
</script>
"""
```

---

## Part 3: Simplified HTML Template

```julia
html_template_v2 = mt"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{{:protein_name}}} motifs</title>
    <style>
        /* Inline CSS here or load from data URL */
        {{{:css_content}}}
    </style>
</head>
<body>    
    <br><br>
    <div class="wrapper">
        <div id="nav" style="display: flex; justify-content: center;"></div>
        <br><br><br><br><br>
        
        <div class="container">
            {{#:modes}}
            <div class="sliderGroup">
                <div class="imageTextContainer">
                    <div id="imageContainer{{:mode_index}}" class="imageContainer">
                        <img id="img{{:mode_index}}" 
                             src="{{{:first_image}}}" 
                             alt="Mode {{:mode_index}}">
                    </div>
                    <div id="textContainer{{:mode_index}}" class="textContainer">
                        {{#:first_texts}}
                        <p id="text{{:mode_index}}_{{.[index]}}" class="imageText">{{{.}}}</p>
                        {{/:first_texts}}
                    </div>
                </div>
                
                {{#:has_slider}}
                <div id="sliderContainer{{:mode_index}}" class="sliderContainer">
                    <input id="valR{{:mode_index}}" 
                           type="range" 
                           min="0" 
                           max="{{:max_index}}" 
                           value="0">
                    <span id="range{{:mode_index}}">{{{:first_label}}}</span>
                </div>
                {{/:has_slider}}
            </div>
            {{/:modes}}
        </div>
    </div>
    
    <!-- Modals -->
    <div id="highlightModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal()">&times;</span>
            <div id="highlightedSequences"></div>
        </div>
    </div>

    <div id="highlightModal_cluster">
        <div id="highlightContent">
            <span class="close" onclick="closeModal_cluster()">&times;</span>
            <div class="modal-column">
                <img id="modalImage" src="" alt="Image">
            </div>
            <div class="modal-column">
                <p id="modalText"></p>
            </div>
        </div>
    </div>

    <div id="highlightModal_text">
        <div id="highlightModal_text_content">
            <span class="close" onclick="closeModal_text()">&times;</span>
            <div class="modal-column">
                <p id="modalText1"></p>
                <button id="copyButton" onclick="copyText()">copy string</button>
            </div>
        </div>
    </div>

    <div id="highlightModal_img">
        <div id="highlightModal_img_content">
            <span class="close" onclick="closeModal_img()">&times;</span>
            <div class="modal-column">
                <img id="modalImage1" src="" alt="Image">
            </div>
        </div>
    </div>
    
    {{{:script_content}}}
</body>
</html>
"""
```

---

## Part 4: Main Generation Function

```julia
"""
Generate a complete, self-contained HTML page
"""
function generate_page(j::Int, protein_name::String, mode_count::Int)
    # 1. Prepare all data
    data = prepare_page_data(j, mode_count, protein_name)
    
    # 2. Generate modular script
    script_html = render(script_template_modular, data)
    
    # 3. Load and inline CSS
    css_content = read("styles.css", String)
    
    # 4. Add script and CSS to data
    data["script_content"] = script_html
    data["css_content"] = css_content
    
    # 5. Render final HTML
    html = render(html_template_v2, data)
    
    # 6. Write to file
    write("output/index$j.html", html)
    
    println("✓ Generated index$j.html (self-contained, no server needed)")
end

# Generate all pages
for j in 1:6
    generate_page(j, "MyProtein", get_mode_count(j))
end
```

---

## Key Improvements

### ✅ No Server Dependency
- All data inline
- No `fetch()` calls
- Open HTML directly in browser

### ✅ Memory Efficient
- FASTA files processed once at build-time
- Pre-rendered highlighted HTML
- Browser only stores what's displayed

### ✅ Modular & Maintainable
- Clear separation: Navigation, Slider, Modal
- Single responsibility per module
- Easy to debug and extend

### ✅ Performance
- No runtime parsing
- Instant page load
- Smooth interactions

### ✅ Portable
- Single HTML file per page
- Share via email, USB, static host
- Works offline

---

## Migration Path

### Phase 1: Start Simple
1. Inline the JSON data first
2. Test that sliders still work
3. Gradually add pre-rendering

### Phase 2: Pre-render Sequences
1. Add `prepare_highlighted_sequences()`
2. Store HTML in data structure
3. Update modal to use pre-rendered HTML

### Phase 3: Modularize JavaScript
1. Wrap in IIFE (Immediately Invoked Function Expression)
2. Use classes for sliders
3. Create Modal module

### Phase 4: Inline Everything
1. Embed CSS
2. Remove external script file
3. Create truly self-contained HTML

---

## Testing Checklist

- [ ] Open HTML file directly (file://) - should work
- [ ] All sliders function correctly
- [ ] Modals open/close properly
- [ ] Sequence highlighting displays correctly
- [ ] Navigation between pages works
- [ ] Copy text functionality works
- [ ] ESC key closes modals
- [ ] File size reasonable (< 5MB per page)

---

## Bonus: Optional Optimizations

### For Very Large Datasets

```julia
# Compress highlighted sequences
using CodecZlib

function compress_html(html::String)
    compressed = transcode(GzipCompressor, Vector{UInt8}(html))
    return base64encode(compressed)
end

# In template:
"""
highlightedSequences: {
    '{{:csv_id}}': decompress('{{:compressed_html}}')
}

function decompress(base64) {
    // Decompress on-demand
    const compressed = atob(base64);
    const decompressed = pako.inflate(compressed, { to: 'string' });
    return decompressed;
}
"""
```

### Progressive Enhancement

```julia
# Generate "light" version first, then enhance
function generate_progressive_page(j::Int)
    # Basic version with first combination only
    basic_data = prepare_basic_data(j)
    
    # Full version with all combinations
    full_data = prepare_full_data(j)
    
    # User can choose which to generate
end
```

---

## Summary

This refactored solution:
1. **Eliminates all server dependencies** - works with file:// protocol
2. **Reduces memory usage** - pre-renders at build time
3. **Improves maintainability** - modular, organized code
4. **Enhances performance** - no runtime parsing
5. **Increases portability** - single, self-contained HTML files

The key insight: **Use Julia's power at build-time, keep runtime simple.**