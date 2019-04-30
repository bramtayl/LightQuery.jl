function type_names(it::Val{It}) where It
    @inline field(i) = fieldtype(fieldtype(It, i), 1)()
    ntuple(field, type_length(it))
end

empty_item_names(it, ::HasEltype) = type_names(Val{eltype(it)}())
empty_item_names(it, ::EltypeUnknown) = type_names(Val{@default_eltype(it)}())

item_names(it) =
    if isempty(it)
        empty_item_names(it, IteratorEltype(it))
    else
        map(first, first(it))
    end

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
    Peek(it, names = item_names(it); max_rows = 4)

Get a peek of an iterator which returns items with `propertynames`. Will show no more than `max_rows`.

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
Peek(it::It, names = item_names(it); max_rows = 4) where {It} = Peek{names, It}(it, max_rows)
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
    make_columns(it, names = item_names(it))

Collect into columns with `names`. Always eager, see [`columns`](@ref) for lazy version.

```jldoctest make_columns
julia> using LightQuery

julia> it = @name [(a = 1, b = 1.0), (a = 2, b = 2.0)];

julia> make_columns(it)
((a, [1, 2]), (b, [1.0, 2.0]))

julia> empty!(it);

julia> make_columns(it)
((a, Int64[]), (b, Float64[]))
```
"""
make_columns(it, names = item_names(it)) =
    names(unzip(Generator(row -> map(value, row), it), Val{length(names)}()))
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
