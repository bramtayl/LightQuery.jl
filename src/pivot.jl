"""
    to_rows(columns)

Iterator over `rows` of a table. Always lazy. Inverse of [`to_columns`](@ref). Use [`Peek`](@ref) to view.

```jldoctest
julia> using LightQuery

julia> @name collect(to_rows((a = [1, 2], b = [1.0, 2.0])))
2-element Array{Tuple{Tuple{Name{:a},Int64},Tuple{Name{:b},Float64}},1}:
 ((`a`, 1), (`b`, 1.0))
 ((`a`, 2), (`b`, 2.0))
```
"""
to_rows(columns) = Generator(map(first, columns), zip(map(value, columns)...))
export to_rows

struct Peek{Rows}
    rows::Rows
    maximum_length::Int
end

export Peek
"""
    Peek(rows, maximum_length = 4)

Peek an iterator which returns named tuples. Will show no more than `maximum_length` rows.

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
Peek(rows) = Peek(rows, 4)

make_any(values) = Any[values...]

function show(output::IO, peek::Peek)
    if isa(IteratorSize(peek.rows), Union{HasLength, HasShape})
        if length(peek.rows) > peek.maximum_length
            println(output, "Showing $(peek.maximum_length) of $(length(peek.rows)) rows")
        end
    else
        println(output, "Showing at most $(peek.maximum_length) rows")
    end
    columns = make_columns(take(
        peek.rows,
        peek.maximum_length
    ))
    rows = map(make_any, zip(map(value, columns)...))
    pushfirst!(rows, make_any(map(key, columns)))
    show(output, MD(Table(rows, make_any(map(x -> :r, columns)))))
end

"""
    to_columns(rows)

Inverse of [`to_rows`](@ref). Always lazy, see [`make_columns`](@ref) for an eager version.

```jldoctest
julia> using LightQuery

julia> @name to_columns(to_rows((a = [1, 2], b = [1.0, 2.0])))
((`a`, [1, 2]), (`b`, [1.0, 2.0]))
```
"""
to_columns(rows::Generator{<: Zip, <: Some{Name}}) =
    rows.f(get_columns(rows.iter))
export to_columns
