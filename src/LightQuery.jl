module LightQuery

include("Nameless.jl")

import Base: map, join, count
import Base.Iterators: drop, product, Filter, Generator
import Markdown: MD, Table

drop_one(x) = Iterators.Drop(x, 1)

export rows
"""
    rows(data)

```jldoctest
julia> using LightQuery

julia> rows((a = [1, 2], b = [2, 1]))
2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Int64}},1}:
 (a = 1, b = 2)
 (a = 2, b = 1)
```
"""
rows(n::NamedTuple) = map(NamedTuple{keys(n)}, zip(n...))

export columns
"""
    columns(data)

```jldoctest
julia> using LightQuery

julia> columns([(a = 1, b = 2), (a = 2, b = 1)])
(a = [1, 2], b = [2, 1])
```
"""
function columns(iterator, the_keys = keys(first(iterator)))
    NamedTuple{the_keys}(map(key -> map(item -> item[key], iterator), the_keys))
end

export flatten_columns
"""
    flatten_columns(iterator)

Flatten the columns of an iterator of named tuples.

```jldoctest
julia> using LightQuery

julia> flatten_columns([(a = [1, 2], b = [4, 3]), (a = [3, 4], b = [2, 1])])
(a = [1, 2, 3, 4], b = [4, 3, 2, 1])
```
"""
function flatten_columns(x)
    first_row = map(copy, first(x))
    foreach(
        second_row ->
            map(
                (a, b) -> append!(a, b),
                first_row, second_row
            ),
        drop_one(x)
    )
    first_row
end

export where
"""
    where(data, f)

```jldoctest
julia> using LightQuery

julia> where((a = [1, 2], b = [2, 1]), @_ _.b .> 1)
(a = [1], b = [2])
```
"""
function where(n::NamedTuple, f)
    which = f(n)
    map(x -> x[which], n)
end

export order_by
"""
    order_by(data, s::Symbol)

```jldoctest
julia> using LightQuery

julia> order_by((a = [1, 2], b = [2, 1]), :b)
(a = [2, 1], b = [1, 2])
```
"""
function order_by(n::NamedTuple, s::Symbol)
    order = sortperm(n[s])
    map(x -> x[order], n)
end

export based_on
"""
    based_on(data; kwargs...)

```jldoctest
julia> using LightQuery

julia> based_on((a = 1, b = 2), c = @_ _.a + _.b)
(c = 3,)
```
"""
based_on(data::NamedTuple; kwargs...) = map(f -> f(data), kwargs.data)

export transform
"""
    transform(data; kwargs...)

```jldoctest
julia> using LightQuery

julia> transform((a = 1, b = 2), c = @_ _.a + _.b)
(a = 1, b = 2, c = 3)
```
"""
transform(data::NamedTuple; kwargs...) = merge(data, based_on(data; kwargs...))

export select
"""
    select(data, args...)

```jldoctest
julia> using LightQuery

julia> select((a = 1, b = 2, c = 3), :a, :c)
(a = 1, c = 3)
```
"""
select(data::NamedTuple, args...) =
    NamedTuple{args}(map(
        name -> getproperty(data, name),
        args
    ))

function get_groups(x::Vector)
    result = UnitRange{Int}[]
    old_index = 1
    item = x[1]
    for (index, new_item) in drop_one(enumerate(x))
        if new_item != item
            push!(result, old_index:index-1)
            old_index = index
            item = new_item
        end
    end
    push!(result, old_index : length(x))
end

export group_by
"""
    group_by(data, s::Symbol)

```jldoctest
julia> using LightQuery

julia> group_by((a = [1, 1, 2, 2], b = [1, 2, 3, 4]), :b)
2-element Array{NamedTuple{(:a, :b),Tuple{Array{Int64,1},Array{Int64,1}}},1}:
 (a = [1, 1], b = [1, 2])
 (a = [2, 2], b = [3, 4])
```
"""
function group_by(data::NamedTuple, s::Symbol)
    ranges = get_groups(data[s])
    rows(map(x -> map(range -> x[range], ranges), data))
end

export inner_join
"""
    inner_join(data1, data2)

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
function inner_join(data1, data2, s::Symbol)
    map(pair -> merge(pair[1], pair[2]), Filter(
        pair -> getproperty(pair[1], s) == getproperty(pair[2], s),
        product(data1, data2)
    ))
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
    result = collect(Any, Generator(x -> [x...], data))
    pushfirst!(result, first_row)
    MD(Table(result, map(x -> :r, first_row)))
end

end
