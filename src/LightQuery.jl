module LightQuery

# re-export CSV
import CSV
export CSV
using Base: diff_names, SizeUnknown, HasEltype, HasLength, HasShape, Generator,
    EltypeUnknown, @propagate_inbounds, _collect, @default_eltype
import Base: iterate, IteratorEltype, eltype, IteratorSize, axes, size, length,
    IndexStyle, getindex, setindex!, push!, similar, view, isless, zip,
    setindex_widen_up_to, empty, push_widen, filter, show, _nt_names
using IterTools: @ifsomething
using MacroTools: @capture
using Base.Meta: quot
using Base.Iterators: product, flatten, Zip, Filter, take, _zip_iterator_size,
    _zip_iterator_eltype
using MappedArrays: mappedarray
using Markdown: Table, MD
export flatten

include("Nameless.jl")
include("Unzip.jl")
include("iterators.jl")
include("named_tuples.jl")

export rows
"""
    rows(it)

Iterator over `rows` of a `NamedTuple` of arrays. Inverse of
[`columns`](@ref). See [`Peek`](@ref) for a way to view `rows`.

```jldoctest
julia> using LightQuery

julia> (a = [1, 2], b = [1.0, 2.0]) |> rows |> Peek
|  :a |  :b |
| ---:| ---:|
|   1 | 1.0 |
|   2 | 2.0 |
```
"""
function rows(it)
    names = Names(propertynames(it)...)
    Generator(names, zip(Tuple(it)...))
end

export columns
"""
    columns(it)

Inverse of [`rows`](@ref).

```jldoctest
julia> using LightQuery

julia> (a = [1], b = [1.0]) |> rows |> columns
(a = [1], b = [1.0])
```
"""
columns(g::Generator{It, Names{names}}) where {It <: ZippedArrays, names} =
    g.f(g.iter.arrays)

@inline auto_columns(it::Generator{It, Names{names}}) where {It, names} = names
@inline auto_columns(it::Filter) = auto_columns(it.itr)
@inline auto_columns(it) = _auto_columns(it, IteratorEltype(it))
@inline _auto_columns(it, ::HasEltype) = _nt_names(first_fallback(it, eltype(it)))
@inline _auto_columns(it, ::EltypeUnknown) = _nt_names(first_fallback(it, @default_eltype(it)))

first_fallback(it, ::Type{Any}) = typeof(first(it))
first_fallback(it, something) = something
first_fallback(it, ::Type{Union{}}) = error("Can't infer names due to inner function error")

export make_columns
"""
    make_columns(it)

Collect into columns. See also [`columns`](@ref). In same cases, will
error if inference cannot detect the names. In this case, use the names of the first
row.

```jldoctest; filter = r"error(::String) at .*"
julia> using LightQuery

julia> using Test: @inferred

julia> [(a = 1, b = 1.0), (a = 2, b = 2.0)] |>
        make_columns
(a = [1, 2], b = [1.0, 2.0])

julia> @> 1:2 |>
        over(_, x -> error()) |>
        make_columns
ERROR: Can't infer names due to inner function error
```
"""
function make_columns(it)
    the_names = auto_columns(it)
    NamedTuple{the_names}((unzip(Generator(Tuple, it), length(the_names))))
end

struct Peek{Names, It}
    it::It
    max_columns::Int
    max_rows::Int
end

export Peek
"""
    Peek(it; max_columns = 7, max_rows = 4)

Get a peek of an iterator which returns named tuples. If inference cannot detect
names, it will use the names of the first item. Map a [`Names`](@ref) object
[`over`](@ref) `it` to help inference.

```jldoctest
julia> using LightQuery

julia> [(a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8)] |>
        Peek
Showing 7 of 8 columns
|  :a |  :b |  :c |  :d |  :e |  :f |  :g |
| ---:| ---:| ---:| ---:| ---:| ---:| ---:|
|   1 |   2 |   3 |   4 |   5 |   6 |   7 |

julia> (a = 1:6,) |>
        rows |>
        Peek
Showing 4 of 6 rows
|  :a |
| ---:|
|   1 |
|   2 |
|   3 |
|   4 |

julia> @> (a = 1:2,) |>
        rows |>
        when(_, @_ _.a > 1) |>
        Peek
Showing at most 4 rows
|  :a |
| ---:|
|   2 |
```
"""
Peek(it::It; max_columns = 7, max_rows = 4) where It =
    Peek{auto_columns(it), It}(it, max_columns, max_rows)

function show(io::IO, p::Peek{the_names}) where {the_names}
    less_names =
        if length(the_names) > p.max_columns
            println(io, "Showing $(p.max_columns) of $(length(the_names)) columns")
            the_names[1:p.max_columns]
        else
            the_names
        end
    if isa(IteratorSize(p.it), Union{HasLength, HasShape})
        if length(p.it) > p.max_rows
            println(io, "Showing $(p.max_rows) of $(length(p.it)) rows")
        end
    else
        println(io, "Showing at most $(p.max_rows) rows")
    end
    less_rows = take(over(p.it, row -> Any[Names(less_names...)(row)...]), p.max_rows) |> collect
    pushfirst!(less_rows, Any[less_names...])
    show(io, MD(Table(less_rows, [map(x -> :r, less_names)...])))
end

end
