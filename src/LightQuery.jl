module LightQuery

include("Nameless.jl")

import Base: map, join, count
import Base.Iterators: drop, product, Filter, Generator
import Markdown: MD, Table

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

export name
"""
    name(data, columns...)

```jldoctest
julia> using LightQuery

julia> name((1, 2), :a, :b)
(a = 1, b = 2)
```
"""
name(data, columns...) = NamedTuple{columns}(data)

export gather
"""
    gather(data, new_column, columns...)

```jldoctest
julia> using LightQuery

julia> gather((a = 1, b = 2, c = 3), :d, :a, :c)
(b = 2, d = (a = 1, c = 3))
```
"""
function gather(data::NamedTuple, new_column::Symbol, columns::Symbol...)
    merge(
        remove(data, columns...),
        name((select(data, columns...),), new_column)
    )
end

export spread
"""
    spread(data, new_column)

```jldoctest
julia> using LightQuery

julia> spread((b = 2, d = (a = 1, c = 3)), :d)
(b = 2, a = 1, c = 3)
```
"""
function spread(data, column)
    merge(
        remove(data, column),
        data[column]
    )
end

export rename
"""
    rename(data; renames...)

```jldoctest
julia> using LightQuery

julia> rename((a = 1, b = 2), :a => :c)
(b = 2, c = 1)
```
"""
function rename(data::NamedTuple, renames...)
    olds = map(pair -> pair.first, renames)
    merge(
        remove(data, olds...),
        NamedTuple{map(pair -> pair.second, renames)}(select(data, olds...)...)
    )
end

export select
"""
    select([data], columns::Symbol...)

```jldoctest
julia> using LightQuery

julia> data = (a = 1, b = 2, c = 3);

julia> select(data, :a, :c)
(a = 1, c = 3)

julia> select(:a, :c)(data)
(a = 1, c = 3)
```
"""
select(data::NamedTuple, columns::Symbol...) =
    NamedTuple{columns}(map(
        name -> data[name],
        columns
    ))

select(columns::Symbol...) = row -> select(row, columns...)

export same_at
"""
    same_at([data1::NamedTuple, data2::NamedTuple], columns::Symbol...)

```jldoctest
julia> using LightQuery

julia> data1 = (a = 1, b = 2); data2 = (a = 1, b = 3);

julia> same_at(data1, data2, :a)
true

julia> same_at(:a)(data1, data2)
true
```
"""
same_at(data1::NamedTuple, data2::NamedTuple, columns::Symbol...) =
    select(data1, columns...) == select(data2, columns...)

same_at(columns::Symbol...) = (data1, data2) -> same_at(data1, data2, columns...)

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

end
