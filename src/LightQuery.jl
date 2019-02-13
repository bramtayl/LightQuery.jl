module LightQuery

import Base: axes, copyto!, eltype, empty, getindex, getproperty, IndexStyle,
    IteratorEltype, IteratorSize, isless, length, iterate, merge, _nt_names,
    push!, push_widen, size, setindex!, setindex_widen_up_to, show, similar,
    view, zip
using Base: _collect, @default_eltype, diff_names, EltypeUnknown, Generator, HasEltype,
    HasLength, HasShape, @propagate_inbounds, SizeUnknown, sym_in
using Base.Iterators: Filter, flatten, product, take, Zip, _zip_iterator_eltype,
    _zip_iterator_size
using Base.Meta: quot
import CSV
using IterTools: @ifsomething
using MacroTools: @capture
using MappedArrays: mappedarray
using Markdown: MD, Table
export CSV, File, Generator, Filter, flatten

include("macros.jl")
include("Unzip.jl")
include("rows.jl")
include("columns.jl")

"""
    rows(it)

Iterator over `rows` of a `NamedTuple` of arrays. Inverse of
[`columns`](@ref). See [`Peek`](@ref) for a way to view `rows`.

```jldoctest
julia> using LightQuery

julia> (a = [1, 2], b = [1.0, 2.0]) |>
        rows |>
        collect
2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Float64}},1}:
 (a = 1, b = 1.0)
 (a = 2, b = 2.0)
```
"""
function rows(it)
    names = Names(propertynames(it)...)
    @> it |>
        names |>
        Tuple |>
        zip(_...) |>
        Generator(names, _)
end
export rows

"""
    columns(it)

Inverse of [`rows`](@ref).

```jldoctest
julia> using LightQuery

julia> (a = [1], b = [1.0]) |>
        rows |>
        columns
(a = [1], b = [1.0])
```
"""
columns(g::Generator{It, Names{names}}) where {It <: ZippedArrays, names} =
    g.f(g.iter.arrays)
@inline auto_columns(it::Generator{It, Names{names}}) where {It, names} = names
@inline auto_columns(it::Filter) = auto_columns(it.itr)
@inline auto_columns(it) = _auto_columns(it, IteratorEltype(it))
@inline _auto_columns(it, ::HasEltype) =
    first_fallback(it, eltype(it)) |>
    _nt_names
@inline _auto_columns(it, ::EltypeUnknown) =
    first_fallback(it, @default_eltype(it)) |>
    _nt_names
first_fallback(it, ::Type{NamedTuple}) = typeof(first(it))
first_fallback(it, ::Type{Any}) = typeof(first(it))
first_fallback(it, something) = something
first_fallback(it, ::Type{Union{}}) =
    error("Can't infer names due to inner function error")
export columns

export make_columns
"""
    make_columns(it)

Collect into columns. See also [`columns`](@ref). If inference cannot detect
names, it will use the names of the first item. Use a `Generator` of `Names` to
be more explicit if necessary.

```jldoctest
julia> using LightQuery

julia> [(a = 1, b = 1.0), (a = 2, b = 2.0)] |>
        make_columns
(a = [1, 2], b = [1.0, 2.0])

julia> @> [(a = 1,), (a = 2, b = 2.0)] |>
        Generator(Names(:a, :b), _) |>
        make_columns
(a = [1, 2], b = Union{Missing, Float64}[missing, 2.0])
```
"""
function make_columns(it)
    the_names = auto_columns(it)
    selector = Names(the_names...)
    @inline unwrap(row) = Tuple(selector(row))
    selector(unzip(Generator(unwrap, it), Val(length(the_names))))
end

struct Peek{Names, It}
    it::It
    max_rows::Int
end

export Peek
"""
    Peek(it; max_rows = 4)

Get a peek of an iterator which returns named tuples. If inference cannot detect
names, it will use the names of the first item.

```jldoctest
julia> using LightQuery

julia> [(a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8)] |>
        Peek
|  :a |  :b |  :c |  :d |  :e |  :f |  :g |  :h |
| ---:| ---:| ---:| ---:| ---:| ---:| ---:| ---:|
|   1 |   2 |   3 |   4 |   5 |   6 |   7 |   8 |

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
        Filter((@_ _.a > 1), _) |>
        Peek
Showing at most 4 rows
|  :a |
| ---:|
|   2 |
```
"""
Peek(it::It; max_rows = 4) where It =
    Peek{auto_columns(it), It}(it, max_rows)

function show(io::IO, p::Peek{the_names}) where {the_names}
    if isa(IteratorSize(p.it), Union{HasLength, HasShape})
        if length(p.it) > p.max_rows
            println(io, "Showing $(p.max_rows) of $(length(p.it)) rows")
        end
    else
        println(io, "Showing at most $(p.max_rows) rows")
    end
    flat(row) = Any[Names(the_names...)(row)...]
    less_rows =
        @> Generator(flat, p.it) |>
        take(_, p.max_rows) |>
        collect
    pushfirst!(less_rows, Any[the_names...])
    @> the_names |>
        map(x -> :r, _) |>
        [_...] |>
        Table(less_rows, _) |>
        MD |>
        show(io, _)
end

"""
    row_type(f::CSV.File)

Find the type of a row of a `CSV.File` if it was converted to a
[`named_tuple`](@ref). Useful to make type annotations to ensure stability.

```jldoctest
julia> using LightQuery

julia> @> "test.csv" |>
        CSV.File(_, allowmissing = :auto) |>
        row_type
NamedTuple{(:a, :b),T} where T<:Tuple{Int64,Float64}
```
"""
@noinline row_type(f::CSV.File) = NamedTuple{(f.names...,), T} where T <: Tuple{f.types...}
export row_type

end
