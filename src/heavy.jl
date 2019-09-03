function count_one(something)
    true
end

function lengthed(iterator)
    Length(iterator, count(over(iterator, count_one)))
end

"""
    when_columns(columns, a_function)

An eager and column-wise alternative to [`when`](@ref).

```jldoctest
julia> using LightQuery

julia> @name when_columns((a = [1, 2], b = [1, 2]), @_ _.a > 1)
((`a`, [2]), (`b`, [2]))
```
"""
function when_columns(columns, a_function)
    make_columns(lengthed(when(Rows(columns), a_function)))
end
export when_columns

"""
    add_columns(columns, a_function)

An eager and column-wise alternative to [`over`](@ref).

```jldoctest
julia> using LightQuery

julia> @name add_columns((a = [1], b = [1]), @_ (c = _.a + _.b,))
((`a`, [1]), (`b`, [1]), (`c`, [2]))
```
"""
function add_columns(columns, a_function)
    columns..., make_columns(over(Rows(columns), a_function))...
end
export add_columns

"""
    order_columns(columns, a_function)

An eager and column-wise alternative to [`order`](@ref).

```jldoctest
julia> using LightQuery

julia> @name order_columns((a = [2, 1], b = [2, 1]), :a)
((`a`, [1, 2]), (`b`, [1, 2]))
```
"""
function order_columns(columns, a_function)
    make_columns(order(Rows(columns), a_function))
end
export order_columns

function merge_left(left_row, right_row, both_names)
    remove(left_row, both_names...)...,
    both_names(left_row)...,
    remove(right_row, both_names...)...
end
function merge_right(left_row, right_row, both_names)
    remove(left_row, both_names...)...,
    both_names(right_row)...,
    remove(right_row, both_names...)...
end

function over_merge_left(one_row, many_rows, both_names)
    over(many_rows,
        let one_row = one_row, both_names = both_names
            function merge_capture(many_row)
                merge_left(one_row, many_row, both_names)
            end
        end
    )
end

function over_merge_right(one_row, many_rows, both_names)
    over(many_rows,
        let one_row = one_row
            function merge_capture(many_row)
                merge_right(one_row, many_row, both_names)
            end
        end
    )
end

function inner_join_pair((one_row, (key2, many_rows)), both_names)
    over_merge_left(one_row, many_rows, both_names)
end

"""
    inner_join(one_columns, many_columns)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns. One-to-many.

```jldoctest
julia> using LightQuery

julia> @name inner_join((a = [1, 2], b = [1, 2]), (a = [1, 1, 3], c = [1, 1, 3]))
((`b`, [1, 1]), (`a`, [1, 1]), (`c`, [1, 1]))
```
"""
function inner_join(one_columns, many_columns)
    one_names = map_unrolled(key, one_columns)
    many_names = map_unrolled(key, many_columns)
    both_names = diff_unrolled(one_names, diff_unrolled(one_names, many_names))
    make_columns(flatten(over(
        mix(Name{:inner}(),
            By(Rows(one_columns), both_names),
            By(Group(By(Rows(many_columns), both_names)), first)
        ),
        let both_names = both_names
            function inner_join_pair_capture(nested)
                inner_join_pair(nested, both_names)
            end
        end
    )))
end
export inner_join

function left_join_pair((one_row, (key2, many_rows)), dummy_many_rows, both_names)
    over_merge_left(one_row, many_rows, both_names)
end

function left_join_pair((one_row, zilch)::Tuple{Any, Missing}, dummy_many_rows, both_names)
    over_merge_left(one_row, dummy_many_rows, both_names)
end

function dummy_many_column((name, column))
    name, missing
end

"""
    left_join(one_columns, many_columns)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns. One-to-many.

```jldoctest
julia> using LightQuery

julia> @name left_join((a = [1, 2], b = [1, 2]), (a = [1, 1, 3], c = [1, 1, 3]))
((`b`, [1, 1, 2]), (`a`, [1, 1, 2]), (`c`, Union{Missing, Int64}[1, 1, missing]))
```
"""
function left_join(one_columns, many_columns)
    one_names = map_unrolled(key, one_columns)
    many_names = map_unrolled(key, many_columns)
    both_names = diff_unrolled(one_names, diff_unrolled(one_names, many_names))
    one_rows = Rows(one_columns)
    make_columns(flatten(over(
            mix(Name{:left}(),
                By(one_rows, both_names),
                By(Group(By(Rows(many_columns), both_names)), first)
            ),
            let dummy_many_rows = (map_unrolled(dummy_column, many_columns),)
                function left_join_pair_capture(nested)
                    left_join_pair(nested, dummy_many_rows, both_names)
                end
            end
        ))
    )
end
export left_join

function right_join_pair((one_row, (key2, many_rows)), dummy_one_row, both_names)
    over_merge_right(one_row, many_rows, both_names)
end

function right_join_pair((zilch, (key2, many_rows))::Tuple{Missing, Any}, dummy_one_row, both_names)
    over_merge_right(dummy_one_row, many_rows, both_names)
end

function dummy_column((name, value))
    (name, missing)
end

"""
    right_join(one_columns, many_columns)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns. One-to-many.

```jldoctest
julia> using LightQuery

julia> @name right_join((a = [1, 2], b = [1, 2]), (a = [1, 1, 3], c = [1, 1, 3]))
((`b`, Union{Missing, Int64}[1, 1, missing]), (`a`, [1, 1, 3]), (`c`, [1, 1, 3]))
```
"""
function right_join(one_columns, many_columns)
    one_names = map_unrolled(key, one_columns)
    many_names = map_unrolled(key, many_columns)
    both_names = diff_unrolled(one_names, diff_unrolled(one_names, many_names))
    many_rows = Rows(many_columns)
    make_columns(Length(
        flatten(over(
            mix(Name{:right}(),
                By(Rows(one_columns), both_names),
                By(Group(By(many_rows, both_names)), first)
            ),
            let dummy_one_row = map_unrolled(dummy_column, one_columns)
                function right_join_pair_capture(nested)
                    right_join_pair(nested, dummy_one_row, both_names)
                end
            end
        )),
        length(many_rows)
    ))
end
export right_join

function outer_join_pair((one_row, (key2, many_rows)), dummy_one_row, dummy_many_rows, both_names)
    over_merge_left(one_row, many_rows, both_names)
end

function outer_join_pair((one_row, zilch)::Tuple{Any, Missing}, dummy_one_row, dummy_many_rows, both_names)
    over_merge_left(one_row, dummy_many_rows, both_names)
end

function outer_join_pair((zilch, (key2, many_rows))::Tuple{Missing, Any}, dummy_one_row, dummy_many_rows, both_names)
    over_merge_right(dummy_one_row, many_rows, both_names)
end

function outer_join_pair((zilch, zilch)::Tuple{Missing, Missing}, dummy_one_row, dummy_many_rows, both_names)
    over_merge_left(dummy_one_row, dummy_many_rows, both_names)
end

"""
    outer_join(one_columns, many_columns)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns. One-to-many.

```jldoctest
julia> using LightQuery

julia> @name outer_join((a = [1, 2], b = [1, 2]), (a = [1, 1, 3], c = [1, 1, 3]))
((`b`, Union{Missing, Int64}[1, 1, 2, missing]), (`a`, [1, 1, 2, 3]), (`c`, Union{Missing, Int64}[1, 1, missing, 3]))
"""
function outer_join(one_columns, many_columns)
    one_names = map_unrolled(key, one_columns)
    many_names = map_unrolled(key, many_columns)
    both_names = diff_unrolled(one_names, diff_unrolled(one_names, many_names))
    (dummy_key, dummy_many_rows) =
        first(Group(By(
            Rows(map_unrolled(dummy_many_column, many_columns)),
            both_names
        )))
    make_columns(flatten(over(
        mix(Name{:outer}(),
            By(Rows(one_columns), both_names),
            By(Group(By(Rows(many_columns), both_names)), first)
        ),
        let dummy_one_row = map_unrolled(dummy_column, one_columns),
            dummy_many_rows = (map_unrolled(dummy_column, many_columns),)
            function outer_join_pair_capture(nested)
                outer_join_pair(nested, dummy_one_row, dummy_many_rows, both_names)
            end
        end
    )))
end
export outer_join

"""
    group_columns(columns, group_function, summarize_function)

An eager and column-wise alternative to [`mix`](@ref). Joins summarize_by commonly named
columns.

```jldoctest
julia> using LightQuery

julia> @name @> (a = [1, 1, 2, 2], b = [1, 2, 3, 4]) |>
        summarize_by(_, (:a,), @_ (c = sum(_.b),))
((`a`, [1, 2]), (`c`, [3, 7]))
```
"""
function summarize_by(columns, group_function, summarize_function)
    make_columns(over(
        lengthed(Group(By(Rows(columns), group_function))),
        let summarize_function = summarize_function
            function replacement((a_key, rows))
                a_key..., summarize_function(to_columns(rows))...
            end
        end
    ))
end
export summarize_by
