export Name
"""
    Name(name)

Force into the type domain. Can also be used as a function to `getproperty`

```jldoctest
julia> using LightQuery

julia> Name(:a)((a = 1,))
1
```
"""
struct Name{name} end

@inline Name(name) = Name{name}()
@inline inner_name(::Name{name}) where name = name

(::Name{name})(it) where name = getproperty(it, name)

export named_tuple
"""
    named_tuple(it)

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
function named_tuple(it)
    names = Tuple(propertynames(it))
    @inline inner_getproperty(name) = getproperty(it, name)
    NamedTuple{names}(map(inner_getproperty, names))
end

export transform
"""
    transform(it; assignments...)

Merge `assignments` into `it`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred transform((a = 1,), b = 1.0)
(a = 1, b = 1.0)
```
"""
transform(it; assignments...) =
    merge(it, assignments)

export gather
"""
    gather(it, name, names...)

Gather all the it in `names` into a single `name`. Inverse of
[`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = gather(x, :d, :a, :c);

julia> @inferred test((a = 1, b = 1.0, c = 1//1))
(b = 1.0, d = (a = 1, c = 1//1))
```
"""
@inline gather(it, name, names...) = merge(
    remove(it, names...),
    NamedTuple{(name,)}((Names(names...)(it),))
)

export spread
"""
    spread(it::NamedTuple, name)

Unnest nested it in `name`. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = spread(x, :d);

julia> @inferred test((b = 1.0, d = (a = 1, c = 1//1)))
(b = 1.0, a = 1, c = 1//1)
```
"""
@inline spread(it, name) = merge(
    remove(it, name),
    getproperty(it, name)
)

struct Names{names} end

(::Names{names})(it) where names =
    NamedTuple{names}(it)

export Names
"""
    Names(names...)

Force into the type domain. Can be used to as a function to select columns.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = Names(:a)(x);

julia> @inferred test((a = 1, b = 1.0))
(a = 1,)
```
"""
@inline Names(names...) = Names{names}()

export remove
"""
    remove(it, names...)

Remove `names`. Inverse of [`transform`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = remove(x, :b);

julia> @inferred test((a = 1, b = 1.0))
(a = 1,)
```
"""
@inline remove(it, names...) =
    Names(diff_names(Tuple(propertynames(it)), names)...)(it)

export rename
"""
    rename(it; renames::Name...)

Rename `it`. Use [`Name`](@ref) for type stability; constants don't propagate
through keyword arguments :(

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = rename(x, c = Name(:a));

julia> @inferred test((a = 1, b = 1.0))
(b = 1.0, c = 1)
```
"""
@inline function rename(it; renames...)
    old_names = inner_name.(Tuple(renames.data))
    new_names = Tuple(propertynames(renames.data))
    merge(
        remove(it, old_names...),
        Names(new_names...)(Tuple(Names(old_names...)(it)))
    )
end

export in_common
"""
    in_common(it1, it2)

Find the names in common between `it1` and `it2`.

```jldoctest
julia> using LightQuery

julia> in_common((a = 1, b = 1.0), (a = 2, c = 2//2))
(:a,)
```
"""
@inline in_common(it1, it2) =
    diff_names(
        Tuple(propertynames(it1)),
        diff_names(propertynames(it1), propertynames(it2))
    )
