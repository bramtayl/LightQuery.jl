function type_names(name_values_type::Val{NameValues}) where NameValues
    @inline name_at(index) = fieldtype(fieldtype(NameValues, index), 1)()
    ntuple(name_at, type_length(name_values_type))
end

empty_item_names(rows, ::HasEltype) = type_names(Val{eltype(rows)}())
empty_item_names(rows, ::EltypeUnknown) =
    type_names(Val{@default_eltype(rows)}())

item_names(rows) =
    if isempty(rows)
        empty_item_names(rows, IteratorEltype(rows))
    else
        map(first, first(rows))
    end

"""
    to_rows(columns)

Iterator over `rows` of a table. Always lazy. Inverse of [`to_columns`](@ref). See [`Peek`](@ref) for a way to view.

```jldoctest
julia> using LightQuery

julia> @name collect(to_rows((a = [1, 2], b = [1.0, 2.0])))
2-element Array{Tuple{Tuple{LightQuery.Name{:a},Int64},Tuple{LightQuery.Name{:b},Float64}},1}:
 ((`a`, 1), (`b`, 1.0))
 ((`a`, 2), (`b`, 2.0))
```
"""
to_rows(columns) = Generator(map(first, columns), zip(map(second, columns)...))
export to_rows

struct Peek{Names, Rows}
    rows::Rows
    maximum_length::Int
end

export Peek
"""
    Peek(rows, some_names = item_names(rows); maximum_length = 4)

Get a peek of an iterator which returns items with `propertynames`. Will show no more than `maximum_length` rows.

```jldoctest Peek
julia> using LightQuery

julia> @name Peek(to_rows((a = 1:5, b = 5:-1:1)))
Showing 4 of 5 rows
| `a` | `b` |
| ---:| ---:|
|   1 |   5 |
|   2 |   4 |
|   3 |   3 |
|   4 |   2 |
```
"""
Peek(rows::Rows, Names = item_names(rows); maximum_length = 4) where {Rows} =
    Peek{Names, Rows}(rows, maximum_length)

function show(output::IO, peek::Peek{Names}) where {Names}
    if isa(IteratorSize(peek.rows), Union{HasLength, HasShape})
        if length(peek.rows) > peek.maximum_length
            println(output, "Showing $(peek.maximum_length) of $(length(peek.rows)) rows")
        end
    else
        println(output, "Showing at most $(peek.maximum_length) rows")
    end
    flat(row) = Any[map(second, row)...]
    less_rows = collect(take(Generator(flat, peek.rows), peek.maximum_length))
    pushfirst!(less_rows, Any[Names...])
    show(output, MD(Table(less_rows, [map(x -> :r, Names)...])))
end

"""
    to_columns(rows)

Inverse of [`to_rows`](@ref). Always lazy, see [`make_columns`](@ref) for eager
version.

```jldoctest
julia> using LightQuery

julia> @name to_columns(to_rows((a = [1, 2], b = [1.0, 2.0])))
((`a`, [1, 2]), (`b`, [1.0, 2.0]))
```
"""
to_columns(rows::Generator{<: Rows, <: Some{Name}}) =
    rows.f(rows.iter.columns)
export to_columns

"""
    make_columns(rows, some_names = item_names(rows))

Collect into columns with `some_names`. Always eager, see [`to_columns`](@ref) for lazy version.

```jldoctest make_columns
julia> using LightQuery

julia> rows = @name [(a = 1, b = 1.0), (a = 2, b = 2.0)];

julia> make_columns(rows)
((`a`, [1, 2]), (`b`, [1.0, 2.0]))

julia> empty!(rows);

julia> make_columns(rows)
((`a`, Int64[]), (`b`, Float64[]))
```
"""
make_columns(rows, some_names = item_names(rows)) =
    some_names(unzip(
        Generator(row -> map(second, row), rows),
        Val{length(some_names)}()
    ))
export make_columns
