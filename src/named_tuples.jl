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

export named_tuple
"""
    named_tuple(x)

Coerce to a `named_tuple`. For performance with working with arbitrary structs,
explicitly define inlined `propertynames`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inline Base.propertynames(p::Pair) = (:first, :second);

julia> @inferred named_tuple(:a => 1)
(first = :a, second = 1)
```
"""
function named_tuple(x)
    names = propertynames(x)
    @inline inner(name) = getproperty(x, name)
    Names(names...)(Tuple(map(inner, names)))
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
    Names(name)((Names(names...)(data),))
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

struct Names{Symbols} end

function (::Names{Symbols})(x) where Symbols
    NamedTuple{Symbols}(x)
end

export Names
"""
    Names(names...)

Names in the type domain. Can be used to select columns.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = Names(:a)(x);

julia> @inferred test((a = 1, b = 2.0))
(a = 1,)
```
"""
@inline Names(symbols...) = Names{symbols}()

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
    Names(diff_names(propertynames(data), names)...)(data)

export rename
"""
    rename(data; renames...)

Rename data. Use [`Name`](@ref) for type stability; constants don't propagate
through keyword arguments.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = rename(x, c = Name(:a));

julia> @inferred test((a = 1, b = 2.0))
(b = 2.0, c = 1)
```
"""
@inline function rename(data; renames...)
    renames_data = renames.data
    old_names = inner_name.(Tuple(renames_data))
    new_names = propertynames(renames_data)
    merge(
        remove(data, old_names...),
        Names(new_names...)(Tuple(Names(old_names...)(data)))
    )
end

export in_common
"""
    in_common(data1, data2)

Find the names in common between `data1` and `data2`.

```jldoctest
julia> using LightQuery

julia> in_common((a = 1, b = 2.0), (a = 1, c = 3.0))
(:a,)
```
"""
@inline in_common(data1, data2) = diff_names(propertynames(data1), diff_names(propertynames(data1), propertynames(data2)))
