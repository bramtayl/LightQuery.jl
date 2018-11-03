module LightQuery

include("Nameless.jl")

import Base: map, join, count
import Base.Iterators: drop, product, Filter, Generator
import Markdown: MD, Table

drop_one(x) = Iterators.Drop(x, 1)

export as_rows
"""
    as_rows(data)

```jldoctest
julia> using LightQuery

julia> as_rows((a = [1, 2], b = [2, 1]))
2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Int64}},1}:
 (a = 1, b = 2)
 (a = 2, b = 1)
```
"""
as_rows(data::NamedTuple) = map(NamedTuple{keys(data)}, zip(data...))

export as_columns
"""
    as_columns(data)

```jldoctest
julia> using LightQuery

julia> as_columns([(a = 1, b = 2), (a = 2, b = 1)])
(a = [1, 2], b = [2, 1])
```
"""
function as_columns(iterator, columns = keys(first(iterator)))
    NamedTuple{columns}(map(key -> map(item -> item[key], iterator), columns))
end

export ungroup
"""
    ungroup(data)

```jldoctest
julia> using LightQuery

julia> ungroup([(a = [1, 2], b = [4, 3]), (a = [3, 4], b = [2, 1])])
(a = [1, 2, 3, 4], b = [4, 3, 2, 1])
```
"""
function ungroup(data)
    first_row = map(copy, first(data))
    foreach(
        second_row ->
            map(
                (a, b) -> append!(a, b),
                first_row, second_row
            ),
        drop_one(data)
    )
    first_row
end

export where
"""
    where(data, condition)

```jldoctest
julia> using LightQuery

julia> where((a = [1, 2], b = [2, 1]), @_ _.b .> 1)
(a = [1], b = [2])
```
"""
function where(data::NamedTuple, condition)
    whiches = condition(data)
    map(column -> column[whiches], data)
end

export order_by
"""
    order_by(data, columns...)

```jldoctest
julia> using LightQuery

julia> order_by((a = [1, 2], b = [2, 1]), :b)
(a = [2, 1], b = [1, 2])
```
"""
function order_by(data::NamedTuple, columns...)
    order = sortperm(zip(select(data, columns...)...))
    map(column -> column[order], data)
end

export based_on
"""
    based_on(data; assignments...)

```jldoctest
julia> using LightQuery

julia> based_on((a = 1, b = 2), c = @_ _.a + _.b)
(c = 3,)
```
"""
based_on(data::NamedTuple; assignments...) = map(f -> f(data), assignments.data)

export transform
"""
    transform(data; assignments...)

```jldoctest
julia> using LightQuery

julia> transform((a = 1, b = 2), c = @_ _.a + _.b)
(a = 1, b = 2, c = 3)
```
"""
transform(data::NamedTuple; assignments...) = merge(data, based_on(data; assignments...))

export select
"""
    select(data, columns...)

```jldoctest
julia> using LightQuery

julia> select((a = 1, b = 2, c = 3), :a, :c)
(a = 1, c = 3)
```
"""
select(data::NamedTuple, columns...) =
    NamedTuple{columns}(map(
        name -> data[name],
        columns
    ))

function get_groups(data::Vector)
    result = UnitRange{Int}[]
    old_index = 1
    item = data[1]
    for (index, new_item) in drop_one(enumerate(data))
        if new_item != item
            push!(result, old_index:index-1)
            old_index = index
            item = new_item
        end
    end
    push!(result, old_index : length(data))
end

export chunk_by
"""
    chunk_by(data, columns...)

```jldoctest
julia> using LightQuery

julia> chunk_by([(a = 1, b = 1), (a = 1, b = 2), (a = 2, b = 3), (a = 2, b = 4)], :a)
2-element Array{Array{NamedTuple{(:a, :b),Tuple{Int64,Int64}},1},1}:
 [(a = 1, b = 1), (a = 1, b = 2)]
 [(a = 2, b = 3), (a = 2, b = 4)]
```
"""
function chunk_by(data, cols...)
    ranges = get_groups(map(row -> select(row, cols...), data))
    map(range -> data[range], ranges)
end

export group_by
"""
    group_by(data, columns...)

```jldoctest
julia> using LightQuery

julia> group_by((a = [1, 1, 2, 2], b = [1, 2, 3, 4]), :a)
2-element Array{NamedTuple{(:a, :b),Tuple{Array{Int64,1},Array{Int64,1}}},1}:
 (a = [1, 1], b = [1, 2])
 (a = [2, 2], b = [3, 4])
```
"""
function group_by(data::NamedTuple, columns...)
    ranges = get_groups(zip(select(data, columns...)...))
    rows(map(column -> map(range -> column[range], ranges), data))
end

subset(nt, columns...) = map(column -> nt[column], columns)

export inner_join
"""
    inner_join(data1, data2, columns...)

```jldoctest
julia> using LightQuery

julia> inner_join(
            [(a = 1, b = 1), (a = 2, b = 2)],
            [(a = 2, c = 2), (a = 3, c = 3)],
            :a
        )
1-element Array{NamedTuple{(:a, :b, :c),Tuple{Int64,Int64,Int64}},1}:
 (a = 2, b = 2, c = 2)
```
"""
function inner_join(data1, data2, columns...)
    map(
        pair -> merge(pair[1], pair[2]),
        Filter(
            pair ->
                select(pair[1], columns...) ==
                select(pair[2], columns...),
            product(data1, data2)
        )
    )
end

export remove
"""
    remove(data, columns...)

```jldoctest
julia> using LightQuery

julia> remove((a = 1, b = 2), :b)
(a = 1,)
```
"""
remove(data, columns...) = Base.structdiff(data, NamedTuple{columns})

export gather
"""
    gather(data, columns...)

```jldoctest
julia> using LightQuery

julia> gather((a = 1, b = 2, c = 3), :b, :c)
((a = 1, key = :b, value = 2), (a = 1, key = :c, value = 3))
```
"""
function gather(data::NamedTuple, columns...)
    rest = remove(data, columns...)
    map(
        column -> merge(rest, (key = column, value = data[column])),
        columns
    )
end

export pretty
"""
    pretty(data)

```jldoctest
julia> using LightQuery

julia> pretty([(a = 1, b = 2), (a = 2, b = 1)])
|  :a |  :b |
| ---:| ---:|
|   1 |   2 |
|   2 |   1 |
```
"""
function pretty(data)
    first_row = [keys(first(data))...]
    result = collect(Any, Generator(row -> [row...], data))
    pushfirst!(result, first_row)
    MD(Table(result, map(column -> :r, first_row)))
end



end
