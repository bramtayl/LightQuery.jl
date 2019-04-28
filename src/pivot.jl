@generated type_names(it) =
    map(pair -> fieldtypes(pair)[1](), fieldtypes(it))

"""
    item_names(it)

Find names of items in `it`. Used in [`Peek`](@ref) and [`make_columns`](@ref).

```jldoctest
julia> using LightQuery

julia> @name item_names([(a = 1, b = 1.0), (a = 2, b = 2.0)])
(a, b)
```
"""
item_names(it) = type_names(first(it))
export item_names

"""
    rows(it)

Iterator over `rows` of a `NamedTuple` of arrays. Always lazy. Inverse of [`columns`](@ref). See [`Peek`](@ref) for a way to view.

```jldoctest
julia> using LightQuery

julia> @name collect(rows((a = [1, 2], b = [1.0, 2.0])))
2-element Array{Tuple{Tuple{LightQuery.Name{:a},Int64},Tuple{LightQuery.Name{:b},Float64}},1}:
 ((a, 1), (b, 1.0))
 ((a, 2), (b, 2.0))
```
"""
rows(it) = Generator(map(first, it), zip(map(value, it)...))
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

julia> @name Peek(rows((a = 1:5, b = 5:-1:1)))
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
    flat(row) = Any[map(value, row)...]
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

julia> @name columns(rows((a = [1, 2], b = [1.0, 2.0])))
((a, [1, 2]), (b, [1.0, 2.0]))
```
"""
columns(it::Generator{<: ZippedArrays, <: Tuple{Name, Vararg{Name}}}) =
    it.f(it.iter.arrays)

export columns

"""
    make_columns(it)

Collect into columns. Always eager, see [`columns`](@ref) for lazy version. Relies on [`item_names`](@ref).

```jldoctest make_columns
julia> using LightQuery

julia> @name make_columns([(a = 1, b = 1.0), (a = 2, b = 2.0)])
((a, [1, 2]), (b, [1.0, 2.0]))
```
"""
function make_columns(it)
    them = item_names(it)
    unwrap(row) = map(value, row)
    them(unzip(Generator(unwrap, it), length(them)))
end
export make_columns

function pair_type(name, a_type)
    typed_name = Name{name}
    if isconcretetype(a_type)
        Tuple{typed_name, a_type}
    else
        Tuple{typed_name, T} where {T <: a_type}
    end
end

"""
    row_type(file)

Get the `row_type` of a `file`.

```jldoctest
julia> using LightQuery

julia> row_type(CSV.File("test.csv"))
Tuple{Tuple{LightQuery.Name{:a},T} where T<:Union{Missing, Int64},Tuple{LightQuery.Name{:b},T} where T<:Union{Missing, Float64}}
```
"""
row_type(file::CSV.File) = Tuple{map(pair_type, file.names, file.types)...}
export row_type
