"""
    to_rows(columns)

Iterator over `rows` of a table. Always lazy. Use [`Peek`](@ref) to view.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @name @inferred collect(to_rows((a = [1, 2], b = [1.0, 2.0])))
2-element Array{Tuple{Tuple{Name{:a},Int64},Tuple{Name{:b},Float64}},1}:
 ((`a`, 1), (`b`, 1.0))
 ((`a`, 2), (`b`, 2.0))
```
"""
to_rows(columns) = over(
    zip(map_unrolled(value, columns)...),
    Apply(map_unrolled(key, columns))
)
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
justification(column) = :r
function show(output::IO, peek::Peek)
    rows = peek.rows
    maximum_length = peek.maximum_length
    if isa(IteratorSize(rows), Union{HasLength, HasShape})
        if length(rows) > maximum_length
            println(output, "Showing $(maximum_length) of $(length(rows)) rows")
        end
    else
        println(output, "Showing at most $(maximum_length) rows")
    end
    columns = make_columns(take(rows, maximum_length))
    rows = map(make_any, zip(map(value, columns)...))
    pushfirst!(rows, make_any(map_unrolled(key, columns)))
    show(output, MD(Table(
        rows,
        make_any(map_unrolled(justification, columns))
    )))
end
