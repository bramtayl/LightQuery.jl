"""
    to_rows(columns)

Iterator over `rows` of a table. Always lazy. Use [`Peek`](@ref) to view. Note
that [`Rows`](@ref) offers more performance, but has stricter requirements than
`to_rows`. [`Rows`](@ref) requires that the iteration state for the first column
can generate an index for all of the colums.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @name @inferred collect(to_rows((a = [1, 2], b = [1.0, 2.0])))
2-element Array{Tuple{Tuple{Name{:a},Int64},Tuple{Name{:b},Float64}},1}:
 ((`a`, 1), (`b`, 1.0))
 ((`a`, 2), (`b`, 2.0))
```
"""
function to_rows(columns)
    over(
        zip(map_unrolled(value, columns)...),
        Apply(map_unrolled(key, columns))
    )
end
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
function Peek(rows)
    Peek(rows, 4)
end

function make_any(values)
    Any[values...]
end
function justification(column)
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

"""
    to_columns(rows)

Convert rows into columns. Always lazy, see [`make_columns`] for an eager
version. In many cases, row-wise access will be more efficient.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @name @inferred to_columns(Rows((a = [1, 2], b = [1.0, 2.0])))
((`a`, [1, 2]), (`b`, [1.0, 2.0]))

julia> @name @inferred to_columns(to_rows((a = [1, 2], b = [1.0, 2.0])))
((`a`, [1, 2]), (`b`, [1.0, 2.0]))

julia> result =
        @name @> (a = [2, 1], b = [2.0, 1.0]) |>
        Rows |>
        order(_, :a) |>
        to_columns |>
        collect(_.b)
2-element Array{Float64,1}:
 1.0
 2.0
"""
function to_columns(rows::Generator)
    rows.f(get_columns(parent(rows)))
end

function OrderView_backwards(index_key, unordered)
    OrderView(unordered, index_key)
end

# OrderView(Rows) => Rows(OrderView)
function to_columns(order_view::OrderView{Iterator}) where {Iterator <: Rows}
    to_columns(Rows(
        partial_map(OrderView_backwards,
            order_view.index_keys,
            order_view.unordered.columns
        ),
        order_view.unordered.names
    ))
end

export to_columns
