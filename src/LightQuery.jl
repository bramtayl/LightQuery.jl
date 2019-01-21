module LightQuery

using Base: diff_names, SizeUnknown, HasEltype, HasLength, HasShape, Generator, promote_op, EltypeUnknown
import Base: iterate, IteratorEltype, eltype, IteratorSize, length, merge, size, view, isless
import IterTools: @ifsomething
using MacroTools: @capture
using Base.Meta: quot
using Base.Iterators: product, flatten, Zip

include("Nameless.jl")
include("iterators.jl")

export Name
"""
    struct Name{T} end

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred Name(:a)((a = 1, b = 2.0,))
1

julia> @inferred merge(Name(:a), Name(:b))
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

julia> @inferred Names(:a)((a = 1, b = 2.0,))
(a = 1,)
```
"""
struct Names{T} end
@inline Names(args...) = Names{args}()
(::Names{T})(x) where T = select(x, Names{T}())

@inline inner(n::Name{T}) where T = T
merge(ns::Name...) = Names{inner.(ns)}()

export unname
"""
    unname

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred unname((a = 1, b = 2.0))
(1, 2.0)

julia> @inferred unname((1, 2.0))
(1, 2.0)

julia> struct Triple{T1, T2, T3}
            first::T1
            second::T2
            third::T3
        end;

julia> Base.propertynames(t::Triple) = (:first, :second, :third);

julia> @inferred unname(Triple(1, 1.0, "a"))
(1, 1.0, "a")

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

julia> @inferred named((a = 1, b = 2.0))
(a = 1, b = 2.0)

julia> struct Triple{T1, T2, T3}
            first::T1
            second::T2
            third::T3
        end;

julia> Base.propertynames(t::Triple) = (:first, :second, :third);

julia> @inferred named(Triple(1, 1.0, "a"))
(first = 1, second = 1.0, third = "a")
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
    gather(data, columns::Names, new_column::Name)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred gather((a = 1, b = 2.0, c = "c"), Names(:a, :c), Name(:d))
(b = 2.0, d = (a = 1, c = "c"))
```
"""
function gather(data, columns::Names, new_column::Name)
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
    select(data, Names{diff_names(propertynames(data), T)}())

export in_common
"""
    in_common(data1, data2)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred in_common((a = 1, b = 2.0), (a = 1, c = "3"))
Names{(:a,)}()
```
"""
function in_common(data1, data2)
    data1_names = propertynames(data1)
    data2_names = propertynames(data2)
    Names{diff_names(data1_names, diff_names(data1_names, data2_names))}()
end

export invert
"""
    invert(n::NamedTuple)

```jldoctest
julia> using LightQuery

julia> invert((a = [1, 2], b = [2, 1])) |> collect
2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Int64}},1}:
 (a = 1, b = 2)
 (a = 2, b = 1)
```
"""
function invert(n::NamedTuple)
	construct = NamedTuple{propertynames(n)}
	Generator(construct, zip(Tuple(n)...))
end

end
