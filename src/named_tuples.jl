struct Name{name} end
"""
    Name(name)

Force into the type domain. Can also be used as a function to `getproperty`

```jldoctest
julia> using LightQuery

julia> @> (a = 1,) |>
        Name(:a)(_)
1
```
"""
@inline Name(name) = Name{name}()
@inline inner_name(::Name{name}) where name = name
(::Name{name})(it) where name = getproperty(it, name)
export Name

struct Names{the_names} end
(::Names{the_names})(it) where the_names = NamedTuple{the_names}(it)
"""
    Names(the_names...)

Force into the type domain. Can be used to as a function to select columns.

```jldoctest
julia> using LightQuery

julia> @> (a = 1, b = 1.0) |>
        Names(:a)(_)
(a = 1,)
```
"""
@inline Names(the_names...) = Names{the_names}()
export Names

"""
    named_tuple(it)

Coerce to a `named_tuple`. For performance with working with arbitrary structs,
requires `propertynames` to constant propagate.

```jldoctest
julia> using LightQuery

julia> @inline Base.propertynames(p::Pair) = (:first, :second);

julia> named_tuple(:a => 1)
(first = :a, second = 1)
```
"""
function named_tuple(it)
    the_names = Tuple(propertynames(it))
    @> map((@_ getproperty(it, _)), the_names) |>
        Names(the_names...)(_)
end
export named_tuple

"""
    transform(it; assignments...)

Merge `assignments` into `it`.

```jldoctest
julia> using LightQuery

julia> transform((a = 1,), b = 1.0)
(a = 1, b = 1.0)
```
"""
transform(it; assignments...) = merge(it, assignments)
export transform

"""
    remove(it, the_names...)

Remove `the_names`. Inverse of [`transform`](@ref).

```jldoctest
julia> using LightQuery

julia> @> (a = 1, b = 1.0) |>
        remove(_, :b)
(a = 1,)
```
"""
@inline remove(it, the_names...) =
    @> propertynames(it) |>
    diff_names(_, the_names) |>
    Names(_...)(it)
export remove

"""
    rename(it; renames::Name...)

Rename `it`. Use [`Name`](@ref) for type stability; constants don't propagate
through keyword arguments :(

```jldoctest
julia> using LightQuery

julia> @> (a = 1, b = 1.0) |>
        rename(_, c = Name(:a))
(b = 1.0, c = 1)
```
"""
@inline function rename(it; renames...)
    old_names = inner_name.(Tuple(renames.data))
    new_names = propertynames(renames.data)
    merge(
        remove(it, old_names...),
        Names(new_names...)(Tuple(Names(old_names...)(it)))
    )
end

"""
    gather(it; assignments...)

For each `key => value` pair in assignments, gather the [`Names`](@ref) in
`value` into a single `key`. Inverse of [`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> @> (a = 1, b = 1.0, c = 1//1) |>
        gather(_, d = Names(:a, :c))
(b = 1.0, d = (a = 1, c = 1//1))
```
"""
@inline function gather(it; assignments...)
    @inline inner_gather(names) = names(it)
    separate = map(inner_gather, assignments.data)
    @> separate |>
        Tuple |>
        merge(_...) |>
        propertynames |>
        remove(it, _...) |>
        merge(_, separate)
end
export gather

"""
    spread(it::NamedTuple, the_names...)

Unnest nested it in `name`. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> @> (b = 1.0, d = (a = 1, c = 1//1)) |>
        spread(_, :d)
(b = 1.0, a = 1, c = 1//1)
```
"""
@inline function spread(it, the_names...)
    @inline inner_getproperty(name) = getproperty(it, name)
    merge(
        remove(it, the_names...),
        inner_getproperty.(the_names)...
    )
end
export spread

export rename

"""
    in_common(it1, it2)

Find the the_names in common between `it1` and `it2`.

```jldoctest
julia> using LightQuery

julia> in_common((a = 1, b = 1.0), (a = 2, c = 2//2))
(:a,)
```
"""
@inline in_common(it1, it2) =
    @> diff_names(propertynames(it1), propertynames(it2)) |>
        diff_names(propertynames(it1), _)
export in_common
