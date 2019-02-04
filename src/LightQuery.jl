module LightQuery

# re-export CSV
import CSV
export CSV
using Base: diff_names, SizeUnknown, HasEltype, HasLength, HasShape, Generator, promote_op, EltypeUnknown, StepRange, @propagate_inbounds, _collect, @default_eltype, show_default
import Base: iterate, IteratorEltype, eltype, IteratorSize, axes, size, length, IndexStyle, getindex, setindex!, push!, similar, view, isless, setindex_widen_up_to, empty, push_widen, filter, show, _nt_names
import IterTools: @ifsomething
using MacroTools: @capture
using Base.Meta: quot
using Base.Iterators: product, flatten, Zip, Filter, take, Take
using MappedArrays: mappedarray
import Markdown: Table, MD
export flatten

include("Nameless.jl")
include("Unzip.jl")
include("iterators.jl")
include("named_tuples.jl")

export rows
"""
    rows(n::NamedTuple)

Iterator over rows of a `NamedTuple` of names. Inverse of [`columns`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> rows((a = [1, 2], b = [2, 1]))
|  :a |  :b |
| ---:| ---:|
|   1 |   2 |
|   2 |   1 |

julia> rows((a = 1:6,))
Showing 4 of 6 rows
|  :a |
| ---:|
|   1 |
|   2 |
|   3 |
|   4 |

julia> rows((a = [1], b = [2], c = [3], d = [4], e = [5], f = [6], g = [7], h = [8]))
Showing 7 of 8 columns
|  :a |  :b |  :c |  :d |  :e |  :f |  :g |
| ---:| ---:| ---:| ---:| ---:| ---:| ---:|
|   1 |   2 |   3 |   4 |   5 |   6 |   7 |
```
"""
function rows(x)
    the_names = Names(propertynames(x)...)
    Generator(the_names, zip(the_names(x)...))
end

export make_columns
"""
    make_columns(it)

Collect into columns. See also [`columns`](@ref). In same cases, will error if
inference cannot detect the names. In this case, map a [`Names`](@ref) object
[`over`](@ref) `it` first.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> (a = [1, 2], b = [1.0, 2.0]) |>
        rows |>
        make_columns
(a = [1, 2], b = [1.0, 2.0])
```
"""
function make_columns(it)
    names = auto_columns(it)
    Names(names...)(unzip(Generator(Tuple, it), length(names)))
end

@inline auto_columns(it::Generator{It, Names{Symbols}}) where {It, Symbols} =
    Symbols
@inline auto_columns(it::Filter) = auto_columns(it.itr)
@inline auto_columns(it) = _auto_columns(it, IteratorEltype(it))
@inline _auto_columns(it, ::HasEltype) = _nt_names(eltype(it))
@inline _auto_columns(it, something) = _nt_names(@default_eltype(it))

_nt_names(::Type{Any}) = error("inference cannot detect names")
_nt_names(::Type{Union{}}) = error("inner error (so inference cannot detect names)")

export columns
"""
    columns(it)

Inverse of [`rows`](@ref).

```jldoctest
julia> using LightQuery

julia> columns(rows((a = [1, 1.0], b = [2, 2.0])))
(a = [1.0, 1.0], b = [2.0, 2.0])
```
"""
columns(g::Generator{It, Names{Symbols}}) where {It <: Zip, Symbols} = g.f(g.iter.is)

@inline function show_table(io::IO, it, names...; max_rows = 4, max_columns = 7)
    if length(names) > max_columns
        println(io, "Showing $max_columns of $(length(names)) columns")
    end
    less_names = collect(take(names, max_columns))
    if isa(IteratorSize(it), Union{HasLength, HasShape})
        if length(it) > max_rows
            println(io, "Showing $max_rows of $(length(it)) rows")
        end
    else
        println(io, "Showing at most $max_rows rows")
    end
    less_rows = take(over(it, x -> Any[Names(less_names...)(x)...]), max_rows) |> collect
    pushfirst!(less_rows, Any[less_names...])
    show(io, MD(Table(less_rows, [map(x -> :r, less_names)...])))
end

function show(io::IO, g::Generator{It, Names{Symbols}}) where {It, Symbols}
    show_table(io, g, Symbols...)
end

function show(io::IO, f::Filter{F, Generator{It, Names{Symbols}}}) where {F, It, Symbols}
    show_table(io, f, Symbols...)
end

struct Peek{Names, It}
    it::It
end

export Peek
"""
    Peek(it)

If an item is a `Generator` using `Names`, LightQuery will show you a peek of
the data in table form. However, not all iterators which yield `NamedTuples`
will print this way; in order to get a peek of them, you need to explicitly
use `Peek`. In same cases, will error if inference cannot detect the names. In
this case, map a [`Names`](@ref) object [`over`](@ref) `it` first.

```jldoctest
julia> using LightQuery

julia> Peek(rows((a = [1, 1.0], b = [2, 2.0])))
|  :a |  :b |
| ---:| ---:|
| 1.0 | 2.0 |
| 1.0 | 2.0 |
```
"""
Peek(it::It) where It = Peek{auto_columns(it), It}(it)

show(io::IO, p::Peek{names}) where {names} = show_table(io, p.it, names...)

end
