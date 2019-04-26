struct Name{it} end
"""
    Name(it)

A typed name. For multiple names, use [`Names`](@ref).

```jldoctest
julia> using LightQuery

julia> Name(:a)((a = 1, b = 2))
1
```
"""
@inline Name(it) = Name{it}()
inner(::Name{it}) where {it} = it
inner(::Type{Name{it}}) where {it} = it
show(io::IO, ::Name{it}) where {it} = print(io, it)
show(io::IO, ::Type{Name{it}}) where {it} = it
(::Name{name})(it) where {name} = getproperty(it, name)
export Name

struct Names{them} end
@inline Names(them...) = Names{them}()
@generated split_names(::Names{them}) where {them} = map(Name, them)
split_names(it) = split_names(merge_names(it))
@generated merge_names(them::Tuple{Vararg{Name}}) =
    Names{ntuple(it -> inner(fieldtype(them, it)), fieldcount(them))}()
merge_names(it) = Names{Tuple(propertynames(it))}()
get_names(it, them::Tuple{Vararg{Name}}) = map(name -> name(it), them)
(call::Names{them})(it) where {them} =
    NamedTuple{them}(get_names(it, split_names(call)))
(::Names{them})(it::Tuple) where {them} = NamedTuple{them}(it)
"""
    Names(them...)

Typed `Names`. For just one name, use [`Name`](@ref).

```jldoctest
julia> using LightQuery

julia> Names(:a, :b)((1, 2))
(a = 1, b = 2)

julia> Names(:a, :b)((a = 1, b = 2, c = 3))
(a = 1, b = 2)
```
"""
@inline Names(them...) = Names{them}()
show(io::IO, it::Names) = show(io, split_names(it))
show(io::IO, ::Type{Names{them}}) where {them} = show(io, split_names(Names{them}()))
export Names

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
named_tuple(it) = merge_names(it)(it)
export named_tuple

flatten_unrolled(::Tuple{}) = ()
flatten_unrolled(them) = first(them)..., flatten_unrolled(tail(them))...
if_not_in(it, them) =
    if it === first(them)
        ()
    else
        if_not_in(it, tail(them))
    end
if_not_in(it, ::Tuple{}) = (it,)
diff_unrolled(::Tuple{}, less) = ()
diff_unrolled(more, less) =
    if_not_in(first(more), less)..., diff_unrolled(tail(more), less)...
union_unrolled(them1, them2) = diff_unrolled(them1, them2)..., them2...
"""
    remove(it, them...)

Remove `them`. Inverse of [`transform`](@ref).

```jldoctest
julia> using LightQuery

julia> remove((a = 1, b = 2), Name(:b))
(a = 1,)
```
"""
function remove(it, them...)
    still = diff_unrolled(split_names(it), them)
    merge_names(still)(get_names(it, still))
end
export remove

"""
    transform(it; them...)

Merge `them` into `it`. Inverse of [`remove`](@ref).

```jldoctest
julia> using LightQuery

julia> transform((a = 1, b = 2), a = 3)
(b = 2, a = 3)
```
"""
function transform(it; them...)
    data = them.data
    new = split_names(data)
    still = diff_unrolled(split_names(it), new)
    merge_names((still..., new...))((get_names(it, still)..., Tuple(data)...))
end
export transform

"""
    rename(it; them...)

Rename `it`.

```jldoctest
julia> using LightQuery

julia> rename((a = 1, b = 2), c = Name(:a))
(b = 2, c = 1)
```
"""
@inline function rename(it; them...)
    data = them.data
    old = Tuple(data)
    still = diff_unrolled(split_names(it), old)
    merge_names((still..., split_names(data)...))(
        (get_names(it, still)..., get_names(it, old)...)
    )
end
export rename

"""
    gather(it; them...)

For each `key => value` pair in `them`, gather the [`Names`](@ref) in `value` into a single `key`. Inverse of [`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> gather((a = 1, b = 2, c = 3), d = Names(:a, :c))
(b = 2, d = (a = 1, c = 3))
```
"""
@inline function gather(it; them...)
    data = them.data
    split = Tuple(data)
    still = diff_unrolled(
        split_names(it),
        flatten_unrolled(map(split_names, split))
    )
    merge_names((still..., split_names(data)...))(
        (get_names(it, still)..., map(names -> names(it), split)...)
    )
end
export gather

"""
    spread(it, them...)

Unnest nested `name` in `them`. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> spread((b = 2, d = (a = 1, c = 3)), Name(:d))
(b = 2, a = 1, c = 3)
```
"""
@inline function spread(it, them...)
    still = diff_unrolled(split_names(it), them)
    split = get_names(it, them)
    merge_names((
        still...,
        flatten_unrolled(map(split_names, split))...
    ))((
        get_names(it, still)...,
        flatten_unrolled(map(Tuple, split))...
    ))
end
export spread
