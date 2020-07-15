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


julia> Peek(Rows(a = 1:5, b = 5:-1:1))
Showing 4 of 5 rows
|   a |   b |
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

function show(output::IO, peek::Peek)
    rows = peek.rows
    maximum_length = peek.maximum_length
    if isa(IteratorSize(rows), Union{HasLength,HasShape})
        if length(rows) > maximum_length
            println(output, "Showing $(maximum_length) of $(length(rows)) rows")
        end
    else
        println(output, "Showing at most $(maximum_length) rows")
    end
    columns = make_columns(take(rows, maximum_length))
    rows = map(make_any, zip(columns...))
    pushfirst!(rows, make_any(String.(propertynames(columns))))
    show(output, MD(Table(rows, make_any(map(function (column)
        :r
    end, columns)))))
end

"""
    function reduce_rows(rows, a_function, columns...)

Reduce a function over each of `columns` in `rows`.

```jldoctest
julia> using LightQuery


julia> using Test: @inferred


julia> @inferred reduce_rows(Rows(a = [1, 1], b = [1.0, 1.0]), +, name"a", name"b")
(a = 2, b = 2.0)
```
"""
function reduce_rows(rows, a_function, columns...)
    reduce(
        let a_function = a_function, columns = columns
            function (row1, row2)
                map(
                    a_function,
                    columns(row1),
                    columns(row2),
                )
            end
        end,
        rows,
    )
end

export reduce_rows
