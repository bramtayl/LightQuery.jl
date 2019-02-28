"""
    named_tuple(it)

Coerce to a `named_tuple`. For performance with working with arbitrary structs, define and `@inline` propertynames.

```jldoctest
julia> using LightQuery

julia> @inline Base.propertynames(p::Pair) = (:first, :second);

julia> named_tuple(:a => 1)
(first = :a, second = 1)
```
"""
function named_tuple(it)
    the_names = Tuple(propertynames(it))
    @inline from_it(name) = getproperty_default(it, name)
    Names(the_names...)(map(from_it, the_names))
end
export named_tuple

@inline getproperty_default(it, name) = getproperty(it, name)
@inline getproperty_default(it::NamedTuple{the_names}, name) where {the_names} =
    if sym_in(name, the_names)
        getproperty(it, name)
    else
        missing
    end
getproperty_default(::Missing, something) = missing
struct Name{name} end
"""
    Name(name)

Create a typed name. Can be used as a function to `getproperty`, with a default to `missing`. For multiple names, see [`Names`](@ref).

```jldoctest
julia> using LightQuery

julia> (a = 1,) |>
        Name(:a)
1

julia> (a = 1,) |>
        Name(:b)
missing

julia> missing |>
        Name(:a)
missing
```
"""
@inline Name(name) = Name{name}()
@inline inner_name(::Name{name}) where {name} = name
(::Name{name})(it) where {name} = getproperty_default(it, name)
export Name

struct Names{the_names} end
function (::Names{the_names})(it) where {the_names}
    @inline from_it(name) = getproperty_default(it, name)
    NamedTuple{the_names}(map(from_it, the_names))
end
(::Names{the_names})(::Missing) where {the_names} =
    NamedTuple{the_names}(map(name -> missing, the_names))
(::Names{the_names})(it::Tuple) where {the_names} = NamedTuple{the_names}(it)
"""
    Names(the_names...)

Create typed names. Can be used to as a function to assign or select names, with a default to `missing`. For just one name, see [`Name`](@ref).

```jldoctest
julia> using LightQuery

julia> (1, 1.0) |>
        Names(:a, :b)
(a = 1, b = 1.0)

julia> (a = 1, b = 1.0) |>
        Names(:a)
(a = 1,)

julia> (a = 1,) |>
        Names(:a, :b)
(a = 1, b = missing)

julia> missing |>
        Names(:a)
(a = missing,)
```
"""
@inline Names(the_names...) = Names{the_names}()
export Names

"""
    rename(it; renames...)

Rename `it`. Because constants do not constant propagate through key-word arguments, wrap with [`Name`](@ref).

```jldoctest
julia> using LightQuery

julia> @> (a = 1, b = 1.0) |>
        rename(_, c = Name(:a))
(b = 1.0, c = 1)
```
"""
@inline function rename(it; renames...)
    old_names = map(inner_name, Tuple(renames.data))
    new_names = propertynames(renames.data)
    merge(
        remove(it, old_names...),
        Names(new_names...)(Tuple(Names(old_names...)(it)))
    )
end
export rename

"""
    transform(it; assignments...)

Merge `assignments` into `it`. Inverse of [`remove`](@ref).

```jldoctest
julia> using LightQuery

julia> @> (a = 1,) |>
        transform(_, b = 1.0)
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
    Names(diff_names(propertynames(it), the_names)...)(it)
export remove

"""
    gather(it; assignments...)

For each `key => value` pair in assignments, gather the [`Names`](@ref) in `value` into a single `key`. Inverse of [`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> @> (a = 1, b = 1.0, c = 1//1) |>
        gather(_, d = Names(:a, :c))
(b = 1.0, d = (a = 1, c = 1//1))
```
"""
@inline function gather(it; assignments...)
    @inline from_it(names) = names(it)
    separate = map(from_it, assignments.data)
    merge(remove(it, propertynames(merge(Tuple(separate)...))...), separate)
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
    @inline from_it(name) = getproperty(it, name)
    merge(remove(it, the_names...), map(from_it, the_names)...)
end
export spread

# piracy
merge(it::NamedTuple, ::Missing) = it
merge(::Missing, it::NamedTuple) = it
