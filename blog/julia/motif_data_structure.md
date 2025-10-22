@def title = "Simplified Julia Data Structures for motifs"
@def published = "21 October 2025"
@def tags = ["julia"]


# Simplified Julia Data Structures

## Original Problems
- 6 separate motif types (pair, triplet, quadruplet, quintuplet, sextuplet)
- 6 separate distance types
- 6 parallel arrays for keys/values/positions/contributions
- Complex Union types hard to maintain
- Inconsistent naming conventions

## Proposed Solution

### 1. Unified Motif and Distance Types

```julia
# Use parametric types instead of separate definitions
const MotifTuple{N} = NamedTuple{ntuple(i -> Symbol(:m, i), N), NTuple{N, String}}
const DistanceTuple{N} = NamedTuple{ntuple(i -> Symbol(:d, i, i+1), N), NTuple{N, Int}}

# Helper functions to create them
motif_tuple(vals::NTuple{N, String}) where N = 
    NamedTuple{ntuple(i -> Symbol(:m, i), N)}(vals)

distance_tuple(vals::NTuple{N, Int}) where N = 
    NamedTuple{ntuple(i -> Symbol(:d, i, i+1), N)}(vals)
```

### 2. Consolidated Data Container

Instead of separate parallel arrays, use a single struct:

```julia
struct MotifData{K, N}
    key::K
    freq::Matrix{float_type}
    positions::Vector{NTuple{4, Int}}
    contrib::Vector{float_type}
    avg_contrib::float_type
    is_positive::Bool
    weights::Vector{Float64}
    distances::Matrix{Float64}
    pval::Float64
end

# For contributions with exclusions
struct MotifDataWithExclusions{K, N}
    key::K
    excluded::Vector{Int}
    contrib::Dict{DistanceTuple{N}, Vector{float_type}}
end
```

### 3. Simplified Type Definitions

```julia
# Main storage types - much cleaner!
const SingleMotifKey = String
const PairMotifKey = MotifTuple{2}
const TripletMotifKey = Tuple{MotifTuple{3}, DistanceTuple{2}}
const QuadrupletMotifKey = Tuple{MotifTuple{4}, DistanceTuple{3}}
const QuintupletMotifKey = Tuple{MotifTuple{5}, DistanceTuple{4}}
const SextupletMotifKey = Tuple{MotifTuple{6}, DistanceTuple{5}}

const AnyMotifKey = Union{
    SingleMotifKey,
    PairMotifKey,
    TripletMotifKey,
    QuadrupletMotifKey,
    QuintupletMotifKey,
    SextupletMotifKey
}

# Now you only need these simple type aliases
const freq_matrix_t = Dict{AnyMotifKey, Matrix{float_type}}
const freq_pos_t = Dict{AnyMotifKey, Vector{NTuple{4, Int}}}
const contrib_t = Dict{AnyMotifKey, Vector{float_type}}
const avg_contrib_t = Dict{AnyMotifKey, float_type}
const is_pos_contrib_t = Dict{AnyMotifKey, Bool}
const weights_t = Dict{AnyMotifKey, Vector{Float64}}
const distances_t = Dict{AnyMotifKey, Matrix{Float64}}
const pvals_t = Dict{AnyMotifKey, Float64}
```

### 4. Alternative: Abstract Type Hierarchy

For even more type safety:

```julia
abstract type MotifKey end

struct SingleMotif <: MotifKey
    m::String
end

struct PairMotif <: MotifKey
    motifs::MotifTuple{2}
    d12::Int
end

struct TripletMotif <: MotifKey
    motifs::MotifTuple{3}
    distances::DistanceTuple{2}
end

struct QuadrupletMotif <: MotifKey
    motifs::MotifTuple{4}
    distances::DistanceTuple{3}
end

# ... and so on

# Then all your types become:
const freq_matrix_t = Dict{<:MotifKey, Matrix{float_type}}
const freq_pos_t = Dict{<:MotifKey, Vector{NTuple{4, Int}}}
# etc.
```

### 5. Utility Functions (Updated)

```julia
# Infer size from any motif key
infer_size(::SingleMotif) = 1
infer_size(::PairMotif) = 2
infer_size(m::TripletMotif) = 3
infer_size(m::QuadrupletMotif) = 4
infer_size(m::QuintupletMotif) = 5
infer_size(m::SextupletMotif) = 6

# Or for tuple-based approach:
infer_size(k::String) = 1
infer_size(k::MotifTuple{N}) where N = N
infer_size(k::Tuple{MotifTuple{N}, DistanceTuple}) where N = N

# Config conversion remains similar
function config2namedtup_fil(config, fil2ind, hp)
    n = length(config) ÷ 2 + 1
    vals = Vector{String}(undef, n)
    for i = 1:n
        fi = config[2*(i-1)+1]
        vals[i] = fi > hp.M ? "$(fil2ind[fi-hp.M])r" : "$(fil2ind[fi])"
    end
    return motif_tuple(Tuple(vals))
end

function config2namedtup_d(config)
    length(config) == 3 && return config[2]
    vals = Tuple(config[2*i] for i = 1:(length(config)÷2))
    return distance_tuple(vals)
end

# Unified config to key conversion
function config_to_key(config)
    motifs = config2namedtup_fil(config, fil2ind, hp)
    length(config) == 1 && return motifs.m1
    length(config) == 3 && return motifs
    distances = config2namedtup_d(config)
    return (motifs, distances)
end
```

## Benefits

1. **Less code duplication**: One parametric type instead of 6 definitions
2. **Type safety**: Compiler can check N parameter matches
3. **Easier to extend**: Adding 7-tuplets just works automatically
4. **Cleaner API**: All operations work uniformly across sizes
5. **Better maintainability**: Change once, applies everywhere
6. **More Julian**: Uses parametric types and multiple dispatch properly

## Migration Strategy

1. Keep old type aliases temporarily for backwards compatibility
2. Add new types alongside existing ones
3. Gradually migrate functions to use new types
4. Remove old types once migration complete

```julia
# Backwards compatibility layer
const pair_motifs_t = MotifTuple{2}
const triplet_motifs_t = MotifTuple{3}
# etc.
```