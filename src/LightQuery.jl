module LightQuery

using Base: diff_names, SizeUnknown, HasEltype, HasLength, HasShape, Generator, promote_op, EltypeUnknown, StepRange, @propagate_inbounds, _collect, @default_eltype
import Base: iterate, IteratorEltype, eltype, IteratorSize, axes, size, length, IndexStyle, getindex, setindex!, push!, similar, merge, view, isless, setindex_widen_up_to, collect, empty, push_widen, getproperty
import IterTools: @ifsomething
using MacroTools: @capture
using Base.Meta: quot
using Base.Iterators: product, flatten, Zip, Filter
using MappedArrays: mappedarray
import DataFrames: DataFrame

include("Nameless.jl")
include("Unzip.jl")
include("iterators.jl")

export pretty
"""
    pretty(x)

Pretty display.

```jldoctest
julia> using LightQuery

julia> pretty((a = [1, 2], b = [1.0, 2.0]))
2×2 DataFrames.DataFrame
│ Row │ a     │ b       │
│     │ Int64 │ Float64 │
├─────┼───────┼─────────┤
│ 1   │ 1     │ 1.0     │
│ 2   │ 2     │ 2.0     │
```
"""
pretty(x) = DataFrame(; x...)

export Name
"""
    Name(x)

Force into the type domain. Can also be used as a function.

```jldoctest
julia> using LightQuery

julia> Name(:a)((a = 1,))
1
```
"""
struct Name{N} end
@inline Name(N) = Name{N}()
@inline inner_name(n::Name{N}) where N = N
@inline inner_name(x) = x
(::Name{N})(x) where N = getproperty(x, N)

@inline function get_names(data, names...)
    @inline inner(name) = getproperty(data, inner_name(name))
    map(inner, names)
end

@inline set_names(data::Tuple, names...) = NamedTuple{inner_name.(names)}(data)

export named_tuple
"""
    named_tuple(x)

Coerce to a `named_tuple`. For performance with working with arbitrary structs,
explicitly define public `propertynames`.

```jldoctest
julia> using LightQuery

julia> Base.propertynames(p::Pair) = (:first, :second);

julia> named_tuple(:a => 1)
(first = :a, second = 1)
```
"""
function named_tuple(x)
    names = propertynames(x)
    set_names(get_names(x, names...), names...)
end

export transform
"""
    transform(data; assignments...)

Merge `assignments` into `data`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred transform((a = 1, b = 2.0), c = "3")
(a = 1, b = 2.0, c = "3")
```
"""
transform(data::NamedTuple; assignments...) =
    merge(data, assignments)

export gather
"""
    gather(data, name, names...)

Gather all the data in `names` into a single `name`. Inverse of
[`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = gather(x, :d, :a, :c);

julia> @inferred test((a = 1, b = 2.0, c = "c"))
(b = 2.0, d = (a = 1, c = "c"))
```
"""
@inline gather(data, name, names...) = merge(
    remove(data, names...),
    set_names((select(data, names...),), name)
)

export spread
"""
    spread(data::NamedTuple, name)

Unnest nested data in `name`. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = spread(x, :d);

julia> @inferred test((b = 2.0, d = (a = 1, c = "c")))
(b = 2.0, a = 1, c = "c")
```
"""
@inline spread(data, name) = merge(
    remove(data, name),
    getproperty(data, name)
)

export select
"""
    select(data::NamedTuple, names...)

Select `names`.

    select(ss::Symbol...)

Curried form.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = select(x, :a);

julia> @inferred test((a = 1, b = 2.0))
(a = 1,)

julia> test(x) = select(:a)(x);

julia> @inferred test((a = 1, b = 2.0))
(a = 1,)
```
"""
@inline select(data, names...) =
    set_names(get_names(data, names...), names...)

@inline function select(ss::Symbol...)
    @inline inner(x) = select(x, ss...)
end

export remove
"""
    remove(data, names...)

Remove `names`. Inverse of [`transform`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = remove(x, :b);

julia> @inferred test((a = 1, b = 2.0))
(a = 1,)
```
"""
@inline remove(data, names...) =
    select(data, diff_names(propertynames(data), names)...)

export rename
"""
    rename(data; renames...)

Rename data. Currently unstable without [`Name`](@ref)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = rename(x, c = Name(:a));

julia> @inferred test((a = 1, b = 2.0))
(b = 2.0, c = 1)
```
"""
@inline function rename(data; renames...)
    old_names = inner_name.(Tuple(renames.data))
    new_names = propertynames(renames.data)
    merge(
        remove(data, old_names...),
        set_names(get_names(data, old_names...), new_names...)
    )
end

export rows
"""
    rows(n::NamedTuple)

Iterator over rows of a `NamedTuple` of names. Inverse of [`columns`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred first(rows((a = [1, 2], b = [2, 1])))
(a = 1, b = 2)
```
"""
function rows(x)
    names = propertynames(x)
    Generator(NamedTuple{propertynames(x)}, zip(get_names(x, names...)...))
end

export columns
"""
    columns(it, names...)

Collect into columns. Inverse of [`rows`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = columns(x, :b, :a);

julia> @inferred test([(a = 1, b = 1.0)])
(b = [1.0], a = [1])

julia> test(when(rows((a = [1, 2], b = [2, 1])), @_ _.a > 1)) |> collect
1-element Array{NamedTuple{(:a, :b),Tuple{Int64,Int64}},1}:
 (a = 2, b = 1)
```
"""
@inline function columns(it, names...)
    typed_names = Name.(names)
    @inline inner(x) = get_names(x, typed_names...)
    set_names(unzip(Generator(inner, it), length(typed_names)), names...)
end

@inline columns(g::Generator{It, F} where {It <: Zip, F <: Type{T} where T <: NamedTuple}, names...) =
    select(g.f(g.iter.is), names...)

@inline function columns(f::Filter{F2, It} where {F2, It <: Generator{It, F} where {It <: Zip, F <: Type{T} where T <: NamedTuple}}, names...)
    template = map(f.flt, f.itr)
    rows(map(
        let template = template
            x -> view(x, template)
        end,
        f.itr.f(f.itr.iter.is)
    ))
end

export column
"""
    column(it, name)

Access just one column.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = column(x, :a);

julia> @inferred test([(a = 1, b = 1.0)]) |> collect
1-element Array{Int64,1}:
 1

julia> @inferred test(rows((a = [1, 2], b = [2, 1])))
2-element Array{Int64,1}:
 1
 2
```
"""
@inline column(g::Generator{It, F} where {It <: Zip, F <: Type{T} where T <: NamedTuple}, name) =
    getproperty(g.f(g.iter.is), inner_name(name))

@inline column(x, name) = Generator(Name(name), x)

end
