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

julia> @name Peek(Rows((a = 1:5, b = 5:-1:1)))
Showing 4 of 5 rows
| `a` | `b` |
| ---:| ---:|
|   1 |   5 |
|   2 |   4 |
|   3 |   3 |
|   4 |   2 |
```
"""
function Peek(rows)
    Peek(rows, 4)
end

function make_any(values)
    Any[values...]
end
@inline function justification(column)
    :r
end
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

@inline function reduce_values(a_function, columns, row1, row2)
    map_unrolled(tuple,
        columns,
        map_unrolled(
            a_function,
            map_unrolled(value, columns(row1)),
            map_unrolled(value, columns(row2))
        )
    )
end

"""
    function reduce_rows(rows, a_function, columns...)

Reduce a function over each of `columns` in `rows`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @name @inferred reduce_rows(Rows((a = [1, 1], b = [1.0, 1.0])), +, :a, :b)
((`a`, 2), (`b`, 2.0))
```
"""
@inline function reduce_rows(rows, a_function, columns...)
    reduce(
        let a_function = a_function, columns = columns
            @inline function reduce_rows_capture(row1, row2)
                reduce_values(a_function, columns, row1, row2)
            end
        end,
        rows
    )
end
export reduce_rows
