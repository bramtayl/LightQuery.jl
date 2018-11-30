module LightQuery

include("Nameless.jl")

import Base: diff_names, merge

export Name
"""
    struct Name{T} end

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> Name(:a)((a = 1, b = 2.0,))
1

julia> merge(Name(:a), Name(:b))
Names{(:a, :b)}()
```
"""
struct Name{T} end
@inline Name(x) = Name{x}()
@inline (::Name{T})(x) where T = getproperty(x, T)

export Names
"""
    struct Names{T} end

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> Names(:a)((a = 1, b = 2.0,))
(a = 1,)
```
"""
struct Names{T} end
@inline Names(args...) = Names{args}()
(::Names{T})(x) where T = select(x, Names(T...))

@inline inner(n::Name{T}) where T = T
merge(ns::Name...) = Names(inner.(ns)...)

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
    name(data, names::Names)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred name((a = 1, b = 2.0), Names(:c, :d))
(c = 1, d = 2.0)
```
"""
name(data, names::Names{T}) where T = NamedTuple{T}(unname(data))

export based_on
"""
    based_on(data; assignments...)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred based_on((a = 1, b = 2.0), c = @_ _.a + _.b)
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

julia> @inferred transform((a = 1, b = 2.0), c = @_ _.a + _.b)
(a = 1, b = 2.0, c = 3.0)
```
"""
transform(data; assignments...) = merge(named(data), based_on(data; assignments...))

export gather
"""
    gather(data, new_column::Name, columns::Names)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred gather((a = 1, b = 2.0, c = "c"), Name(:d), Names(:a, :c))
(b = 2.0, d = (a = 1, c = "c"))
```
"""
function gather(data, new_column::Name, columns::Names)
    merge(
        remove(data, columns),
        name(tuple(select(data, columns)), merge(new_column))
    )
end

export spread
"""
    spread(data, column::Name)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred spread((b = 2.0, d = (a = 1, c = "c")), Name(:d))
(b = 2.0, a = 1, c = "c")
```
"""
function spread(data, column::Name)
    merge(
        remove(data, merge(column)),
        column(data)
    )
end

export rename
"""
    rename(data; renames...)

```jldoctest
julia> using LightQuery

julia> rename((a = 1, b = 2.0), c = Name(:a))
(b = 2.0, c = 1)
```
"""
function rename(data; renames...)
    olds = merge(Tuple(renames.data)...)
    merge(
        remove(data, olds),
        name(unname(select(data, olds)), Names(keys(renames)...))
    )
end

export select
"""
    select(data, columns::Names)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred select((a = 1, b = 2.0), Names(:a))
(a = 1,)
```
"""
select(data, columns::Names{T}) where T =
    name(map(
        name -> getproperty(data, name),
        T
    ), columns)

export remove
"""
    remove(data, columns::Names)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred remove((a = 1, b = 2.0), Names(:b))
(a = 1,)
```
"""
remove(data, columns::Names{T}) where T =
    select(data, Names(diff_names(propertynames(data), T)...))

end
