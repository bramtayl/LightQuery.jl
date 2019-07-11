state_to_index(::AbstractArray, state) = value(state)
state_to_index(::Array, state) = state - 1
state_to_index(filtered::Filter, state) = state_to_index(filtered.itr, state)
state_to_index(mapped::Generator, state) = state_to_index(mapped.iter, state)
state_to_index(zipped::Zip, state) =
    state_to_index(first(get_columns(zipped)), first(state))

"""
    Enumerate{Unenumerated}

Relies on the fact that iteration states can be converted to indices; thus, you might have to define `LightQuery.state_to_index` for unrecognized types. "Sees through" some iterators like [`when`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred collect(Enumerate(when([4, 3, 2, 1], iseven)))
2-element Array{Tuple{Int64,Int64},1}:
 (1, 4)
 (3, 2)
```
"""
struct Enumerate{Unenumerated}
    unenumerated::Unenumerated
end

IteratorEltype(::Type{Enumerate{Unenumerated}}) where {Unenumerated} =
    IteratorEltype(Unenumerated)
eltype(::Type{Enumerate{Unenumerated}}) where {Unenumerated} =
    Tuple{Int, eltype(Unenumerated)}

IteratorSize(::Type{Enumerate{Unenumerated}}) where {Unenumerated} =
    IteratorSize(Unenumerated)
length(enumerated::Enumerate) = length(enumerated.unenumerated)
size(enumerated::Enumerate) = size(enumerated.unenumerated)
axes(enumerated::Enumerate) = axes(enumerated.unenumerated)

function iterate(enumerated::Enumerate)
    item, state = @ifsomething iterate(enumerated.unenumerated)
    (state_to_index(enumerated.unenumerated, state), item), state
end
function iterate(enumerated::Enumerate, state)
    item, state = @ifsomething iterate(enumerated.unenumerated, state)
    (state_to_index(enumerated.unenumerated, state), item), state
end
export Enumerate

"""
    order(unordered, key_function; keywords...)

Generalized sort. `keywords` will be passed to `sort!`; see the documentation there for options. Use [`By`](@ref) to mark that an object has been sorted. Relies on [`Enumerate`](@ref). If the results of `key_function` are type unstable, consider using `hash ∘ key_function` instead.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred order([-2, 1], abs)
2-element view(::Array{Int64,1}, [2, 1]) with eltype Int64:
  1
 -2
```
"""
function order(unordered, key_function; keywords...)
    index_keys = collect(Enumerate(over(unordered, key_function)))
    sort!(index_keys, by = value; keywords...)
    view(unordered, mappedarray(key, index_keys))
end


struct Backwards{Increasing}
    increasing::Increasing
end

"""
    backwards(something)

Reverse sorting order.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred order([1, -2], x -> backwards(abs(x)))
2-element view(::Array{Int64,1}, [2, 1]) with eltype Int64:
 -2
  1
```
"""
backwards(something) = Backwards(something)
export backwards

show(io::IO, descending::Backwards) =
    print(io, "Backwards($(descending.increasing))")

isless(descending_1::Backwards, descending_2::Backwards) =
    isless(descending_2.increasing, descending_1.increasing)

export order

struct Indexed{Key, Value, Unindexed, KeyToIndex} <: AbstractDict{Key, Value}
    unindexed::Unindexed
    key_to_index::KeyToIndex
end

Indexed{Key, Value}(unindexed::Unindexed, key_to_index::KeyToIndex) where {Key, Value, Unindexed, KeyToIndex} =
    Indexed{Key, Value, Unindexed, KeyToIndex}(unindexed, key_to_index)

@propagate_inbounds getindex(indexed::Indexed, a_key) =
    indexed.unindexed[indexed.key_to_index[a_key]]

function get(indexed::Indexed, a_key, default)
    index = get(indexed.key_to_index, a_key, nothing)
    if index === nothing
        default
    else
        indexed.unindexed[index]
    end
end

haskey(indexed::Indexed, a_key) = haskey(indexed.key_to_index, a_key)

function iterate(indexed::Indexed)
    key_index, state = @ifsomething iterate(indexed.key_to_index)
    (key(key_index) => indexed.unindexed[value(key_index)]), state
end
function iterate(indexed::Indexed, state)
    key_index, state = @ifsomething iterate(indexed.key_to_index, state)
    (key(key_index) => indexed.unindexed[value(key_index)]), state
end

IteratorSize(::Type{Indexed{Unindexed, KeyToIndex}}) where {Unindexed, KeyToIndex} =
    IteratorSize(KeyToIndex)
length(indexed::Indexed) = length(indexed.key_to_index)
size(indexed::Indexed) = size(indexed.key_to_index)
axes(indexed::Indexed) = axes(indexed.key_to_index)

IteratorEltype(::Type{Indexed{Unindexed, KeyToIndex}}) where {Unindexed, KeyToIndex} =
    combine_iterator_eltype(IteratorEltype(Unindexed), IteratorEltype(KeyToIndex))
eltype(::Type{Indexed{Unindexed, KeyToIndex}}) where {Unindexed, KeyToIndex} =
    Pair{keytype(KeyToIndex), Union{Missing, eltype(Unindexed)}}

key_index(key_function, index, item) = key_function(item) => index

"""
    index(unindexed, key_function)

Index `unindexed` by the results of `key_function`. Relies on [`Enumerate`](@ref). Results of `key_function` must be unique.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred index([-2, 1], abs)
LightQuery.Indexed{Int64,Int64,Array{Int64,1},Dict{Int64,Int64}} with 2 entries:
  2 => -2
  1 => 1
```
"""
function index(unindexed, key_function)
    key_to_index = collect_similar(
        Dict{Union{}, Union{}}(),
        Generator(let key_function = key_function
            ((index, item),) -> key_index(key_function, index, item)
        end, Enumerate(unindexed))
    )
    Indexed{keytype(key_to_index), eltype(unindexed)}(unindexed, key_to_index)
end
export index

"""
    By(sorted, key_function)

Mark that `sorted` has been pre-sorted by `key_function`. Use with
[`Group`](@ref), or [`mix`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred By([1, -2], abs)
By{Array{Int64,1},typeof(abs)}([1, -2], abs)
```
"""
struct By{Iterator, Key}
    sorted::Iterator
    key_function::Key
end
export By

struct Group{Iterator, Key}
    ungrouped::Iterator
    key_function::Key
end

"""
    Group(ungrouped::By)

Group consecutive keys in `ungrouped`. Requires a presorted object (see [`By`](@ref)). Relies on [`Enumerate`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred collect(Group(By([1, -1, -2, 2, 3, -3], abs)))
3-element Array{Tuple{Int64,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:
 (1, [1, -1])
 (2, [-2, 2])
 (3, [3, -3])

julia> @inferred collect(Group(By(Int[], abs)))
0-element Array{Tuple{Int64,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}
```
"""
Group(sorted::By) = Group(sorted.sorted, sorted.key_function)

IteratorSize(::Type{<: Group})  = SizeUnknown()
IteratorEltype(::Type{<: Group}) = EltypeUnknown()

function get_group(group, state, left_index, right_index, last_result, key_result, is_last)
    (last_result, (@inbounds view(
        group.ungrouped,
        left_index:right_index - 1
    ))), (state, right_index, key_result, is_last)
end

get_last(group, state, last_result, left_index) =
    (last_result, (@inbounds view(
        group.ungrouped,
        left_index:length(group.ungrouped)
    ))), (state, left_index, last_result, true)

iterate(group::Group, (state, left_index, last_result, is_last)) =
    if is_last
        nothing
    else
        item_state = iterate(group.ungrouped, state)
        if item_state === nothing
            return get_last(group, state, last_result, left_index)
        end
        item, state = item_state
        key_result = group.key_function(item)
        while isequal(key_result, last_result)
            item_state = iterate(group.ungrouped, state)
            if item_state === nothing
                return get_last(group, state, last_result, left_index)
            end
            item, state = item_state
            key_result = group.key_function(item)
        end
        right_index = state_to_index(group.ungrouped, state)
        (last_result, (@inbounds view(
            group.ungrouped,
            left_index:right_index - 1
        ))), (state, right_index, key_result, false)
    end

function iterate(group::Group)
    item, state = @ifsomething iterate(group.ungrouped)
    iterate(group, (
        state,
        state_to_index(group.ungrouped, state),
        group.key_function(item),
        false
    ))
end
export Group

abstract type Mix{Left <: By, Right <: By} end

combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()

function next_history(side)
    item, state = @ifsomething iterate(side.sorted)
    (state, item, side.key_function(item))
end
function next_history(side, (state, item, key_result))
    new_item, new_state = @ifsomething iterate(side.sorted, state)
    (new_state, new_item, side.key_function(new_item))
end

struct InnerMix{Left <: By, Right <: By} <: Mix{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{InnerMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
eltype(::Type{InnerMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    Tuple{eltype(LeftIterator), eltype(RightIterator)}

compare(mixed::InnerMix, ::Nothing, ::Nothing) = nothing

struct LeftMix{Left <: By, Right <: By} <: Mix{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{LeftMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
eltype(::Type{LeftMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    Tuple{eltype(LeftIterator), Union{Missing, eltype(RightIterator)}}

IteratorSize(::Type{LeftMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    IteratorSize(LeftIterator)
size(mixed::LeftMix) = size(mixed.left.sorted)
length(mixed::LeftMix) = length(mixed.left.sorted)
axes(mixed::LeftMix) = axes(mixed.left.sorted)

compare(mixed::LeftMix, ::Nothing, ::Nothing) = nothing

struct RightMix{Left <: By, Right <: By} <: Mix{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{RightMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
eltype(::Type{RightMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    Tuple{Union{Missing, eltype(LeftIterator)}, eltype(RightIterator)}

IteratorSize(::Type{RightMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    IteratorSize(RightIterator)
size(mixed::RightMix) = size(mixed.right.sorted)
length(mixed::RightMix) = length(mixed.right.sorted)
axes(mixed::RightMix) = axes(mixed.right.sorted)

compare(mixed::RightMix, ::Nothing, ::Nothing) = nothing

struct OuterMix{Left <: By, Right <: By} <: Mix{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{OuterMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
eltype(::Type{OuterMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    Tuple{Union{Missing, eltype(LeftIterator)}, Union{Missing, eltype(RightIterator)}}

compare(mixed::OuterMix, ::Nothing, ::Nothing) = nothing

IteratorSize(::Type{AType}) where {AType <: Union{InnerMix, OuterMix}} = SizeUnknown()

@inline next_left(mixed::Union{InnerMix, RightMix}, left_history, right_history) =
    iterate(mixed, (left_history, right_history, true, false))
@inline function next_left(mixed::Union{LeftMix, OuterMix}, left_history, right_history)
    left_state, left_item, left_key_result = left_history
    (left_item, missing), (left_history, right_history, true, false)
end

@inline next_right(mixed::Union{InnerMix, LeftMix}, left_history, right_history) =
    iterate(mixed, (left_history, right_history, false, true))
@inline function next_right(mixed::Union{RightMix, OuterMix}, left_history, right_history)
    right_state, right_item, right_key_result = right_history
    (missing, right_item), (left_history, right_history, false, true)
end

compare(mixed::Union{InnerMix, LeftMix}, ::Nothing, right_history) = nothing
@inline function compare(mixed::Union{LeftMix, OuterMix}, left_history, ::Nothing)
    left_state, left_item, left_key_result = left_history
    (left_item, missing), (left_history, nothing, true, false)
end

compare(mixed::Union{InnerMix, RightMix}, left_history, ::Nothing) = nothing
@inline function compare(mixed::Union{RightMix, OuterMix}, ::Nothing, right_history)
    right_state, right_item, right_key_result = right_history
    (missing, right_item), (nothing, right_history, false, true)
end

@inline function compare(mixed, left_history, right_history)
    left_state, left_item, left_key_result = left_history
    right_state, right_item, right_key_result = right_history
    if isless(left_key_result, right_key_result)
        next_left(mixed, left_history, right_history)
    elseif isless(right_key_result, left_key_result)
        next_right(mixed, left_history, right_history)
    else
        (left_item, right_item), (left_history, right_history, true, true)
    end
end

iterate(::Mix, ::Nothing) = nothing
iterate(mixed::Mix) = compare(mixed,
    next_history(mixed.left),
    next_history(mixed.right)
)
iterate(mixed::Mix, (left_history, right_history, next_left, next_right)) =
    if next_left
        if next_right
            compare(mixed,
                next_history(mixed.left, left_history),
                next_history(mixed.right, right_history)
            )
        else
            compare(mixed,
                next_history(mixed.left, left_history),
                right_history
            )
        end
    else
        if next_right
            compare(mixed,
                left_history,
                next_history(mixed.right, right_history)
            )
        else
            compare(mixed, left_history, right_history)
        end
    end

"""
    distinct(repeated, key_function = identity)

Generalized version of `unique`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred distinct([1, 2, missing, missing, 2, 1])
3-element view(::Array{Union{Missing, Int64},1}, [1, 2, 3]) with eltype Union{Missing, Int64}:
 1
 2
  missing
```
"""
function distinct(repeated, key_function = identity)
    location_hashes = unique(
        value,
        Enumerate(Generator(hash ∘ key_function, repeated))
    )
    view(repeated, mappedarray(key, location_hashes))
end

export distinct

# piracy
function copyto!(dictionary::Dict{Key, Value}, pairs::AbstractVector{Tuple{Key, Value}}) where {Key, Value}
    foreach(let dictionary = dictionary
        ((a_key, a_value),) -> dictionary[a_key] = a_value
    end, dictionary)
    nothing
end
similar(old::Dict, ::Type{Tuple{Key, Value}}) where {Key, Value} =
    Dict{Key, Value}(old)

@propagate_inbounds getindex(mapped::Generator, index...) =
    mapped.f(mapped.iter[index...])
@propagate_inbounds view(mapped::Generator, index...) =
    Generator(mapped.f, view(mapped.iter, index...))

@propagate_inbounds getindex_reverse(index, column) = column[index...]
@propagate_inbounds getindex(zipped::Zip, index...) =
    partial_map(getindex_reverse, index, get_columns(zipped))
@propagate_inbounds view_reverse(index, column) = view(column, index...)
@propagate_inbounds view(zipped::Zip, index...) =
    zip(partial_map(view_reverse, index, get_columns(zipped))...)

@propagate_inbounds view(filtered::Filter, index...) =
    view(filtered.itr, index...)

"""
    mix(::Name{:inner},  left::By, right::By)

Find all pairs where `isequal(left.key_function(left.sorted), right.key_function(right.sorted))`.
Assumes `left` and `right` are both strictly sorted (no repeats). If there are
repeats, [`Group`](@ref) first. See [`By`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @name @inferred collect(mix(:inner, By([1, -2, 5, -6], abs), By([-1, 3, -4, 6], abs)))
2-element Array{Tuple{Int64,Int64},1}:
 (1, -1)
 (-6, 6)

julia> @name @inferred collect(mix(:inner, By(Int[], abs), By(Int[], abs)))
0-element Array{Tuple{Int64,Int64},1}

julia> @name @inferred collect(mix(:inner, By([1], abs), By(Int[], abs)))
0-element Array{Tuple{Int64,Int64},1}

julia> @name @inferred collect(mix(:inner, By(Int[], abs), By([1], abs)))
0-element Array{Tuple{Int64,Int64},1}
```
"""
mix(::Name{:inner}, left, right) = InnerMix(left, right)

"""
    mix(::Name{:left}, left::By, right::By)

Find all pairs where `isequal(left.key_function(left.sorted), right.key_function(right.sorted))`,
using `missing` when there is no right match. Assumes `left` and `right` are
both strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first.
See [`By`](@ref).

```jldoctest
julia> using LightQuery

julia> @name collect(mix(:left, By([1, -2, 5, -6], abs), By([-1, 3, -4, 6], abs)))
4-element Array{Tuple{Int64,Union{Missing, Int64}},1}:
 (1, -1)
 (-2, missing)
 (5, missing)
 (-6, 6)

julia> @name collect(mix(:left, By(Int[], abs), By(Int[], abs)))
0-element Array{Tuple{Int64,Union{Missing, Int64}},1}

julia> @name collect(mix(:left, By([1], abs), By(Int[], abs)))
1-element Array{Tuple{Int64,Union{Missing, Int64}},1}:
 (1, missing)

julia> @name collect(mix(:left, By(Int[], abs), By([1], abs)))
0-element Array{Tuple{Int64,Union{Missing, Int64}},1}
```
"""
mix(::Name{:left}, left, right) = LeftMix(left, right)


"""
    mix(::Name{:right}, left::By, right::By)

Find all pairs where `isequal(left.key_function(left.sorted), right.key_function(right.sorted))`,
using `missing` when there is no left match. Assumes `left` and `right` are both
strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first. See
[`By`](@ref).

```jldoctest
julia> using LightQuery

julia> @name collect(mix(:right, By([1, -2, 5, -6], abs), By([-1, 3, -4, 6], abs)))
4-element Array{Tuple{Union{Missing, Int64},Int64},1}:
 (1, -1)
 (missing, 3)
 (missing, -4)
 (-6, 6)

julia> @name collect(mix(:right, By(Int[], abs), By(Int[], abs)))
0-element Array{Tuple{Union{Missing, Int64},Int64},1}

julia> @name collect(mix(:right, By([1], abs), By(Int[], abs)))
0-element Array{Tuple{Union{Missing, Int64},Int64},1}

julia> @name collect(mix(:right, By(Int[], abs), By([1], abs)))
1-element Array{Tuple{Union{Missing, Int64},Int64},1}:
 (missing, 1)
```
"""
mix(::Name{:right}, left, right) = RightMix(left, right)

"""
    mix(::Name{:outer}, left::By, right::By)

Find all pairs where `isequal(left.key_function(left.sorted), right.key_function(right.sorted))`,
using `missing` when there is no left or right match. Assumes `left` and `right`
are both strictly sorted (no repeats). If there are repeats, [`Group`](@ref)
first. See [`By`](@ref).

```jldoctest
julia> using LightQuery

julia> @name collect(mix(:outer, By([1, -2, 5, -6], abs), By([-1, 3, -4, 6], abs)))
6-element Array{Tuple{Union{Missing, Int64},Union{Missing, Int64}},1}:
 (1, -1)
 (-2, missing)
 (missing, 3)
 (missing, -4)
 (5, missing)
 (-6, 6)

julia> @name collect(mix(:outer, By(Int[], abs), By(Int[], abs)))
0-element Array{Tuple{Union{Missing, Int64},Union{Missing, Int64}},1}

julia> @name collect(mix(:outer, By([1], abs), By(Int[], abs)))
1-element Array{Tuple{Union{Missing, Int64},Union{Missing, Int64}},1}:
 (1, missing)

julia> @name collect(mix(:outer, By(Int[], abs), By([1], abs)))
1-element Array{Tuple{Union{Missing, Int64},Union{Missing, Int64}},1}:
 (missing, 1)
```
"""
mix(::Name{:outer}, left, right) = OuterMix(left, right)

export mix
