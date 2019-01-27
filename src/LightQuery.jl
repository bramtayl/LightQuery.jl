module LightQuery

using Base: diff_names, SizeUnknown, HasEltype, HasLength, HasShape, Generator, promote_op, EltypeUnknown, StepRange, @propagate_inbounds, _collect, @default_eltype
import Base: iterate, IteratorEltype, eltype, IteratorSize, axes, size, length, IndexStyle, getindex, setindex!, push!, similar, merge, view, isless, setindex_widen_up_to, collect, empty
import IterTools: @ifsomething
using MacroTools: @capture
using Base.Meta: quot
using Base.Iterators: product, flatten, Zip, Filter
using MappedArrays: mappedarray

include("Nameless.jl")
include("Unzip.jl")
include("iterators.jl")

export Name
"""
    Name(x)

Force into the type domain.

```jldoctest
julia> using LightQuery

julia> Name(:a)
Name{:a}()
```
"""
struct Name{N} end
@inline Name(N) = Name{N}()
@inline inner_name(n::Name{N}) where N = N
@inline inner_name(x) = x

@inline function get_names(data, names...)
    @inline inner(name) = getproperty(data, inner_name(name))
    map(inner, names)
end

@inline set_names(data::Tuple, names...) = NamedTuple{inner_name.(names)}(data)

export named_tuple
"""
    named_tuple(x)

Coerce to a `named_tuple`.

```jldoctest
julia> using LightQuery

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

Apply the functions in assignments to `data`, assign to the corresponding
keys, and merge back in the original.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred transform((a = 1, b = 2.0), c = @_ _.a + _.b)
(a = 1, b = 2.0, c = 3.0)
```
"""
transform(data::NamedTuple; assignments...) =
    merge(data, map(f -> f(data), assignments.data))

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

Rename data. Currently unstable.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = rename(x, c = :a);

julia> test((a = 1, b = 2.0))
(b = 2.0, c = 1)
```
"""
@inline function rename(data; renames...)
    old_names = Tuple(renames.data)
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

# I'm actually super proud of this one.
export columns
"""
    columns(it, names...)

Collect into columns. Inverse of [`rows`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = columns(x, :a, :b);

julia> @inferred test([(a = 1, b = 1.0)])
(a = [1], b = [1.0])
```
"""
@inline function columns(it, names...)
    typed_names = Name.(names)
    @inline inner(x) = get_names(x, typed_names...)
    set_names(unzip(Generator(inner, it), length(typed_names)), typed_names...)
end

end
