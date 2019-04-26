@inline first_fallback(it, ::Type{NamedTuple{names}}) where {names} =
    split_names(Names{names}())
@inline first_fallback(it, ::Type{NamedTuple{names, <: Any}}) where {names} =
    split_names(Names{names}())
@inline first_fallback(it, something) = split_names(first(it))
first_fallback(it, ::Type{Union{}}) =
    error("Can't infer names due to inner function error")
@inline item_names_dispatch(it, ::HasEltype) = first_fallback(it, eltype(it))
@inline item_names_dispatch(it, ::EltypeUnknown) =
    first_fallback(it, @default_eltype(it))
"""
    item_names(it)

Find names of items in `it`. Used in [`Peek`](@ref) and [`make_columns`](@ref).

```jldoctest item_names
julia> using LightQuery

julia> item_names([(a = 1, b = 1.0), (a = 2, b = 2.0)])
(a, b)
```

If inference cannot detect names, it will use `propertynames` of the first item.

```jldoctest item_names
julia> item_names([(a = 1,), (a = 2, b = 2.0)])
(a,)
```
"""
@inline item_names(it) = item_names_dispatch(it, IteratorEltype(it))
@inline item_names(it::Generator{<: Any, Names{names}}) where {names} =
    split_names(Names{names}())
@inline item_names(it::Filter) = item_names(it.itr)
export item_names

"""
    rows(it)

Iterator over `rows` of a `NamedTuple` of arrays. Always lazy. Inverse of [`columns`](@ref). See [`Peek`](@ref) for a way to view.

```jldoctest
julia> using LightQuery

julia> collect(rows((a = [1, 2], b = [1.0, 2.0])))
2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Float64}},1}:
 (a = 1, b = 1.0)
 (a = 2, b = 2.0)
```
"""
function rows(it)
    names = Names{propertynames(it)}()
    Generator(names, zip(Tuple(names(it))...))
end
export rows

struct Peek{Names, It}
    it::It
    max_rows::Int
end
export Peek
"""
    Peek(it; max_rows = 4)

Get a peek of an iterator which returns items with `propertynames`. Will show no more than `max_rows`. Relies on [`item_names`](@ref).

```jldoctest Peek
julia> using LightQuery

julia> Peek(rows((a = 1:5, b = 5:-1:1)))
Showing 4 of 5 rows
|   a |   b |
| ---:| ---:|
|   1 |   5 |
|   2 |   4 |
|   3 |   3 |
|   4 |   2 |
```
"""
Peek(it::It; max_rows = 4) where {It} = Peek{item_names(it), It}(it, max_rows)
function show(io::IO, peek::Peek{them}) where {them}
    if isa(IteratorSize(peek.it), Union{HasLength, HasShape})
        if length(peek.it) > peek.max_rows
            println(io, "Showing $(peek.max_rows) of $(length(peek.it)) rows")
        end
    else
        println(io, "Showing at most $(peek.max_rows) rows")
    end
    flat(row) = Any[get_names(row, them)...]
    less_rows = collect(take(Generator(flat, peek.it), peek.max_rows))
    pushfirst!(less_rows, Any[them...])
    show(io, MD(Table(less_rows, [map(x -> :r, them)...])))
end

"""
    columns(it)

Inverse of [`rows`](@ref). Always lazy, see [`make_columns`](@ref) for eager
version.

```jldoctest
julia> using LightQuery

julia> columns(rows((a = [1], b = [1.0])))
(a = [1], b = [1.0])
```
"""
columns(it::Generator{<: ZippedArrays, <: Names}) = it.f(it.iter.arrays)
export columns

"""
    make_columns(it)

Collect into columns. Always eager, see [`columns`](@ref) for lazy version. Relies on [`item_names`](@ref).

```jldoctest make_columns
julia> using LightQuery

julia> make_columns([(a = 1, b = 1.0), (a = 2, b = 2.0)])
(a = [1, 2], b = [1.0, 2.0])
```
"""
function make_columns(it)
    them = item_names(it)
    selector = merge_names(them)
    unwrap(row) = Tuple(selector(row))
    selector(unzip(Generator(unwrap, it), length(them)))
end
export make_columns
