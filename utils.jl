using Dates
using BibTeX

function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end

"""
    {{blogposts}}

Plug in the list of blog posts contained in the `/blog/` folder.
"""
@delay function hfun_blogposts()
    today = Dates.today()
    curyear = year(today)
    curmonth = month(today)
    curday = day(today)

    # Recursively find all .md files in blog directory and subdirectories
    list = String[]
    for (root, dirs, files) in walkdir("blog")
        for file in files
            if endswith(file, ".md") && file != "index.md"
                # Get relative path from blog directory
                relpath_from_blog = relpath(joinpath(root, file), "blog")
                push!(list, relpath_from_blog)
            end
        end
    end
    
    sorter(p) = begin
        ps  = splitext(p)[1]
        url = "/blog/$ps/"
        surl = strip(url, '/')
        pubdate = pagevar(surl, :published)
        if isnothing(pubdate)
            return Date(Dates.unix2datetime(stat(joinpath("blog", p)).ctime))
        end
        return Date(pubdate, dateformat"d U Y")
    end
    sort!(list, by=sorter, rev=true)

    io = IOBuffer()
    write(io, """<ul class="blog-posts">""")
    for (i, post) in enumerate(list)
        ps  = splitext(post)[1]
        write(io, "<li><span><i>")
        url = "/blog/$ps/"
        surl = strip(url, '/')
        title = pagevar(surl, :title)
        pubdate = pagevar(surl, :published)
        if isnothing(pubdate)
            date    = "$curyear-$curmonth-$curday"
        else
            date    = Date(pubdate, dateformat"d U Y")
        end
        write(io, """$date  </i></span>&emsp;<a href="$url">$title</a>""")
    end
    write(io, "</ul>")
    return String(take!(io))
end

"""
    {{custom_taglist}}

Plug in the list of blog posts with the given tag
"""
function hfun_custom_taglist()::String
    tag = locvar(:fd_tag)
    rpaths = globvar("fd_tag_pages")[tag]
    sorter(p) = begin
        pubdate = pagevar(p, :published)
        if isnothing(pubdate)
            return Date(Dates.unix2datetime(stat(p * ".md").ctime))
        end
        return Date(pubdate, dateformat"d U Y")
    end
    sort!(rpaths, by=sorter, rev=true)

    io = IOBuffer()
    write(io, """<ul class="blog-posts">""")
    # go over all paths
    for rpath in rpaths
        write(io, "<li><span><i>")
        url = get_url(rpath)
        title = pagevar(rpath, :title)
        pubdate = pagevar(rpath, :published)
        if isnothing(pubdate)
            date    = "$curyear-$curmonth-$curday"
        else
            date    = Date(pubdate, dateformat"d U Y")
        end
        # write some appropriate HTML
        write(io, """$date</i></span><a href="$url">$title</a>""")
    end
    write(io, "</ul>")
    return String(take!(io))
end


# BibTeX stuff

function ref_item(ref, infos)
    io = IOBuffer()

    author = infos["author"]
    author_last, author_first = strip.(split(author, ","))

    write(io, "<li id=\"#$ref\">")
    write(io, """$author_first $author_last, <span style="font-style:italic;">$(infos["title"])</span>, $(infos["year"]).""")
    write(io, "</li>")
    return String(take!(io))
end


function hfun_show_refs(refs)
    _, allrefs = parse_bibtex(read(joinpath("_assets", "bibex.bib"), String))
    out = IOBuffer()
    write(out, "<ul>")
    for ref in refs
        infos = get(allrefs, ref, nothing)
        isnothing(infos) && continue
        write(out, ref_item(ref, infos))
    end
    write(out, "</ul>")
    return String(take!(out))
end
