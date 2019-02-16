module LightQuery

import Base: axes, copyto!, eltype, empty, getindex, getproperty, IndexStyle,
    IteratorEltype, IteratorSize, isless, length, iterate, merge, _nt_names,
    push!, push_widen, size, setindex!, setindex_widen_up_to, show, similar,
    view, zip
using Base: _collect, @default_eltype, diff_names, EltypeUnknown, Generator,
    HasEltype, HasLength, HasShape, @propagate_inbounds, SizeUnknown, sym_in
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

Iterator over `rows` of a `NamedTuple` of arrays. Inverse of [`columns`](@ref).
See [`Peek`](@ref) for a way to view `rows`.

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
    Generator(names, zip(Tuple(names(it))...))
end
export rows

"""
    columns(it)

Inverse of [`rows`](@ref). Always lazy, see [`make_columns`](@ref) for eager
version.

```jldoctest
julia> using LightQuery

julia> (a = [1], b = [1.0]) |>
        rows |>
        columns
(a = [1], b = [1.0])
```
"""
columns(it::Generator{It, Names{names}}) where {It <: ZippedArrays, names} =
    it.f(it.iter.arrays)
@inline eltype_names(it::Generator{It, Names{names}}) where {It, names} = names
@inline eltype_names(it::Filter) = eltype_names(it.itr)
@inline eltype_names(it) = eltype_names_dispatch(it, IteratorEltype(it))
@inline eltype_names_dispatch(it, ::HasEltype) = first_fallback(it, eltype(it))
@inline eltype_names_dispatch(it, ::EltypeUnknown) =
    first_fallback(it, @default_eltype(it))
first_fallback(it, ::Type{NamedTuple{names}}) where {names} = names
first_fallback(it, ::Type{NamedTuple{names, types}}) where {names, types} =
    names
first_fallback(it, something) = _nt_names(first(it))
first_fallback(it, ::Type{Union{}}) =
    error("Can't infer names due to inner function error")
export columns

export make_columns
"""
    make_columns(it)

Collect into columns. Always eager, see [`columns`](@ref) lazy version.

```jldoctest make_columns
julia> using LightQuery

julia> [(a = 1, b = 1.0), (a = 2, b = 2.0)] |>
        make_columns
(a = [1, 2], b = [1.0, 2.0])
```

If inference cannot detect names, it will use the names of the first item. Map
[`Names`](@ref) [`over`](@ref) `it` to override this behavior.

```jldoctest make_columns
julia> [(a = 1,), (a = 2, b = 2.0)] |>
        Peek
|  :a |
| ---:|
|   1 |
|   2 |

julia> @> [(a = 1,), (a = 2, b = 2.0)] |>
        over(_, Names(:a, :b)) |>
        Peek
|  :a |      :b |
| ---:| -------:|
|   1 | missing |
|   2 |     2.0 |
```
"""
function make_columns(it)
    the_names = eltype_names(it)
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

Get a peek of an iterator which returns named tuples. Will show no more than
`max_rows`.

```jldoctest Peek
julia> using LightQuery

julia> (a = 1:5, b = 5:-1:1) |>
        rows |>
        Peek
Showing 4 of 5 rows
|  :a |  :b |
| ---:| ---:|
|   1 |   5 |
|   2 |   4 |
|   3 |   3 |
|   4 |   2 |
```

If inference cannot detect names, it will use the names of the first item. Map
[`Names`](@ref) [`over`](@ref) `it` to override this behavior.

```jldoctest Peek
julia> [(a = 1,), (a = 2, b = 2.0)] |>
        Peek
|  :a |
| ---:|
|   1 |
|   2 |

julia> @> [(a = 1,), (a = 2, b = 2.0)] |>
        over(_, Names(:a, :b)) |>
        Peek
|  :a |      :b |
| ---:| -------:|
|   1 | missing |
|   2 |     2.0 |
```
"""
Peek(it::It; max_rows = 4) where It = Peek{eltype_names(it), It}(it, max_rows)
function show(io::IO, peek::Peek{the_names}) where {the_names}
    if isa(IteratorSize(peek.it), Union{HasLength, HasShape})
        if length(peek.it) > peek.max_rows
            println(io, "Showing $(peek.max_rows) of $(length(peek.it)) rows")
        end
    else
        println(io, "Showing at most $(peek.max_rows) rows")
    end
    flat(row) = Any[Names(the_names...)(row)...]
    less_rows = collect(take(Generator(flat, peek.it), peek.max_rows))
    pushfirst!(less_rows, Any[the_names...])
    show(io, MD(Table(less_rows, [map(x -> :r, the_names)...])))
end

"""
    row_type(file::CSV.File)

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
@noinline row_type(file::CSV.File) =
    NamedTuple{(file.names...,), T} where T <: Tuple{file.types...}
export row_type

end
