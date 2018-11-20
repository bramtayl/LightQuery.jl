module LightQuery

include("Nameless.jl")

import Base: diff_names

export unname
"""
    unname

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> unname(:a => 1)
(:a, 1)

julia> @inferred unname((a = 1, b = 2.0))
(1, 2.0)

julia> @inferred unname((1, 2.0))
(1, 2.0)
```
"""
function unname(data)
    names = propertynames(data)
    map(
        name -> getproperty(data, name),
        names
    )
end
unname(data::Tuple) = data
unname(data::NamedTuple) = Tuple(data)

export named
"""
    named(data)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> named(:a => 1)
(first = :a, second = 1)

julia> @inferred named((a = 1, b = 2.0))
(a = 1, b = 2.0)
```
"""
named(data) = NamedTuple{propertynames(data)}(unname(data))
named(data::NamedTuple) = data

export name
"""
    name(data, columns...)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = (a = 1, b = 2.0);

julia> test(x) = name(x, :c, :d);

julia> @inferred test(data)
(c = 1, d = 2.0)
```
"""
@inline name(data, columns...) = NamedTuple{columns}(unname(data))

export based_on
"""
    based_on(data; assignments...)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = (a = 1, b = 2.0);

julia> test(x) = based_on(x, c = @_ _.a + _.b);

julia> @inferred test(data)
(c = 3.0,)
```
"""
based_on(data; assignments...) = map(f -> f(data), assignments.data)

export transform
"""
    transform(data; assignments...)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = (a = 1, b = 2.0);

julia> test(x) = transform(x, c = @_ _.a + _.b);

julia> @inferred test(data)
(a = 1, b = 2.0, c = 3.0)
```
"""
transform(data; assignments...) = merge(named(data), based_on(data; assignments...))

export gather
"""
    gather(data, new_column, columns...)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = (a = 1, b = 2.0, c = "c");

julia> test(x) = gather(x, :d, :a, :c);

julia> @inferred test(data)
(b = 2.0, d = (a = 1, c = "c"))
```
"""
@inline function gather(data, new_column::Symbol, columns::Symbol...)
    merge(
        remove(data, columns...),
        name(tuple(select(data, columns...)), new_column)
    )
end

export spread
"""
    spread(data, new_column)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = (b = 2.0, d = (a = 1, c = "c"));

julia> test(x) = spread(x, :d);

julia> @inferred test(data)
(b = 2.0, a = 1, c = "c")
```
"""
@inline function spread(data, column)
    merge(
        remove(data, column),
        getproperty(data, column)
    )
end

export rename
"""
    rename(data; renames...)

```jldoctest
julia> using LightQuery

julia> rename((a = 1, b = 2.0),  c = :a)
(b = 2.0, c = 1)
```
"""
@inline function rename(data::NamedTuple; renames...)
    olds = Tuple(renames.data)
    merge(
        remove(data, olds...),
        name(unname(select(data, olds...)), keys(renames)...)
    )
end

export in_common
"""
    in_common(data1, data2)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data1 = (a = 1, b = 2); data2 = (a = 1, c = 3);

julia> @inferred in_common(data1, data2)
(:a,)
```
"""
@inline function in_common(data1, data2)
    first_names = propertynames(data1)
    second_names = propertynames(data2)
    diff_names(first_names, diff_names(first_names, second_names))
end


export select
"""
    select([data], columns::Symbol...)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = (a = 1, b = 2.0);

julia> test(x) = select(x, :a);

julia> @inferred test(data)
(a = 1,)

julia> test2(x) = select(:a)(x);

julia> @inferred test2(data)
(a = 1,)
```
"""
@inline select(data, columns::Symbol...) =
    name(map(
        name -> getproperty(data, name),
        columns
    ), columns...)

@inline function select(columns::Symbol...)
    @inline function anonymous(row)
        select(row, columns...)
    end
end

export same_at
"""
    same_at([data1::NamedTuple, data2::NamedTuple], columns::Symbol...)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data1 = (a = 1, b = 2.0); data2 = (a = 1, b = 3.0);

julia> test(data1, data2) = same_at(data1, data2, :a);

julia> @inferred test(data1, data2)
true

julia> test2(data1, data2) = same_at(:a)(data1, data2);

julia> @inferred test2(data1, data2)
true
```
"""
@inline same_at(data1, data2, columns::Symbol...) =
    select(data1, columns...) == select(data2, columns...)

@inline function same_at(columns::Symbol...)
    @inline function anonymous(data1, data2)
        same_at(data1, data2, columns...)
    end
end

export same
"""
    same([data1::NamedTuple, data2::NamedTuple])

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data1 = (a = 1, b = 2.0); data2 = (a = 1, c = 3.0);

julia> @inferred same(data1, data2)
true

julia> @inferred same()(data1, data2)
true
```
"""
same(data1::NamedTuple, data2::NamedTuple) =
    same_at(data1, data2, in_common(data1, data2)...)

same() = (data1, data2) -> same(data1, data2)

export remove
"""
    remove(data, columns...)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = (a = 1, b = 2.0);

julia> test(x) = remove(x, :b);

julia> @inferred test(data)
(a = 1,)
```
"""
@inline remove(data, columns...) =
    select(data, diff_names(propertynames(data), columns)...)

end
