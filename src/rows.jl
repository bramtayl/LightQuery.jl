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

"""
    struct Descending{Increasing}

Reverse sorting order.

```jldoctest
julia> using LightQuery

julia> order([1, -2], Descending ∘ abs)
2-element view(::Array{Int64,1}, [2, 1]) with eltype Int64:
 -2
  1
```
"""
struct Descending{Increasing}
    increasing::Increasing
end

export Descending

show(io::IO, descending::Descending) =
    print(io, "Descending($(descending.increasing))")

isless(x::Descending, y::Descending) = isless(y.increasing, x.increasing)

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
            key_index_capture((index, item)) = key_index(key_function, index, item)
        end, Enumerate(unindexed))
    )
    Indexed{keytype(key_to_index), eltype(unindexed)}(unindexed, key_to_index)
end
export index

"""
    By(sorted, key_function)

Mark that `sorted` has been pre-sorted by `key_function`. Use with
[`Group`](@ref), [`InnerJoin`](@ref), [`LeftJoin`](@ref), [`RightJoin`](@ref),
and [`OuterJoin`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred By([1, -2], abs)
By{Array{Int64,1},typeof(abs)}([1, -2], abs)
```
"""
struct By{Iterator, Key}
    sorted::Iterator
    key::Key
end
export By

struct Group{Iterator, Key}
    ungrouped::Iterator
    key::Key
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
Group(sorted::By) = Group(sorted.sorted, sorted.key)

IteratorSize(::Type{<: Group})  = SizeUnknown()
IteratorEltype(::Type{<: Group}) = EltypeUnknown()

function get_group(group, state, left_index, right_index, last_result, result, is_last)
    (last_result, (@inbounds view(
        group.ungrouped,
        left_index:right_index - 1
    ))), (state, right_index, result, is_last)
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
        result = group.key(item)
        while isequal(result, last_result)
            item_state = iterate(group.ungrouped, state)
            if item_state === nothing
                return get_last(group, state, last_result, left_index)
            end
            item, state = item_state
            result = group.key(item)
        end
        right_index = state_to_index(group.ungrouped, state)
        (last_result, (@inbounds view(
            group.ungrouped,
            left_index:right_index - 1
        ))), (state, right_index, result, false)
    end

function iterate(group::Group)
    item, state = @ifsomething iterate(group.ungrouped)
    iterate(group, (
        state,
        state_to_index(group.ungrouped, state),
        group.key(item),
        false
    ))
end
export Group

abstract type Join{Left <: By, Right <: By} end

combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()

function next_history(side)
    item, state = @ifsomething iterate(side.sorted)
    (state, item, side.key(item))
end
function next_history(side, (state, item, result))
    new_item, new_state = @ifsomething iterate(side.sorted, state)
    (new_state, new_item, side.key(new_item))
end

"""
    InnerJoin(left::By, right::By) <: Join{Left, Right}

Find all pairs where `isequal(left.key(left.sorted), right.key(right.sorted))`.

```jldoctest InnerJoin
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred collect(InnerJoin(By([1, -2, 5, -6], abs), By([-1, 3, -4, 6], abs)))
2-element Array{Tuple{Int64,Int64},1}:
 (1, -1)
 (-6, 6)

julia> @inferred collect(InnerJoin(By(Int[], abs), By(Int[], abs)))
0-element Array{Tuple{Int64,Int64},1}

julia> @inferred collect(InnerJoin(By([1], abs), By(Int[], abs)))
0-element Array{Tuple{Int64,Int64},1}

julia> @inferred collect(InnerJoin(By(Int[], abs), By([1], abs)))
0-element Array{Tuple{Int64,Int64},1}
```

Assumes `left` and `right` are both strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first.
"""
struct InnerJoin{Left <: By, Right <: By} <: Join{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{InnerJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
eltype(::Type{InnerJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    Tuple{eltype(LeftIterator), eltype(RightIterator)}

compare(joined::InnerJoin, ::Nothing, ::Nothing) = nothing

export InnerJoin

"""
    LeftJoin(left::By, right::By) <: Join{Left, Right}

Find all pairs where `isequal(left.key(left.sorted), right.key(right.sorted))`,
using `missing` when there is no right match.

```jldoctest LeftJoin
julia> using LightQuery

julia> collect(LeftJoin(By([1, -2, 5, -6], abs), By([-1, 3, -4, 6], abs)))
4-element Array{Tuple{Int64,Union{Missing, Int64}},1}:
 (1, -1)
 (-2, missing)
 (5, missing)
 (-6, 6)

julia> collect(LeftJoin(By(Int[], abs), By(Int[], abs)))
0-element Array{Tuple{Int64,Union{Missing, Int64}},1}

julia> collect(LeftJoin(By([1], abs), By(Int[], abs)))
1-element Array{Tuple{Int64,Union{Missing, Int64}},1}:
 (1, missing)

julia> collect(LeftJoin(By(Int[], abs), By([1], abs)))
0-element Array{Tuple{Int64,Union{Missing, Int64}},1}
```

Assumes `left` and `right` are both strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first.
"""
struct LeftJoin{Left <: By, Right <: By} <: Join{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{LeftJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
eltype(::Type{LeftJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    Tuple{eltype(LeftIterator), Union{Missing, eltype(RightIterator)}}

IteratorSize(::Type{LeftJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    IteratorSize(LeftIterator)
size(joined::LeftJoin) = size(joined.left.sorted)
length(joined::LeftJoin) = length(joined.left.sorted)
axes(joined::LeftJoin) = axes(joined.left.sorted)

compare(joined::LeftJoin, ::Nothing, ::Nothing) = nothing

export LeftJoin

"""
    RightJoin(left::By, right::By) <: Join{Left, Right}

Find all pairs where `isequal(left.key(left.sorted), right.key(right.sorted))`,
using `missing` when there is no left match.

```jldoctest RightJoin
julia> using LightQuery

julia> collect(RightJoin(By([1, -2, 5, -6], abs), By([-1, 3, -4, 6], abs)))
4-element Array{Tuple{Union{Missing, Int64},Int64},1}:
 (1, -1)
 (missing, 3)
 (missing, -4)
 (-6, 6)

julia> collect(RightJoin(By(Int[], abs), By(Int[], abs)))
0-element Array{Tuple{Union{Missing, Int64},Int64},1}

julia> collect(RightJoin(By([1], abs), By(Int[], abs)))
0-element Array{Tuple{Union{Missing, Int64},Int64},1}

julia> collect(RightJoin(By(Int[], abs), By([1], abs)))
1-element Array{Tuple{Union{Missing, Int64},Int64},1}:
 (missing, 1)
```

Assumes `left` and `right` are both strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first.
"""
struct RightJoin{Left <: By, Right <: By} <: Join{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{RightJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
eltype(::Type{RightJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    Tuple{Union{Missing, eltype(LeftIterator)}, eltype(RightIterator)}

IteratorSize(::Type{RightJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    IteratorSize(RightIterator)
size(joined::RightJoin) = size(joined.right.sorted)
length(joined::RightJoin) = length(joined.right.sorted)
axes(joined::RightJoin) = axes(joined.right.sorted)

compare(joined::RightJoin, ::Nothing, ::Nothing) = nothing

export RightJoin

"""
    OuterJoin(left::By, right::By) <: Join{Left, Right}

Find all pairs where `isequal(left.key(left.sorted), right.key(right.sorted))`,
using `missing` when there is no left or right match.

```jldoctest OuterJoin
julia> using LightQuery

julia> collect(OuterJoin(By([1, -2, 5, -6], abs), By([-1, 3, -4, 6], abs)))
6-element Array{Tuple{Union{Missing, Int64},Union{Missing, Int64}},1}:
 (1, -1)
 (-2, missing)
 (missing, 3)
 (missing, -4)
 (5, missing)
 (-6, 6)

julia> collect(OuterJoin(By(Int[], abs), By(Int[], abs)))
0-element Array{Tuple{Union{Missing, Int64},Union{Missing, Int64}},1}

julia> collect(OuterJoin(By([1], abs), By(Int[], abs)))
1-element Array{Tuple{Union{Missing, Int64},Union{Missing, Int64}},1}:
 (1, missing)

julia> collect(OuterJoin(By(Int[], abs), By([1], abs)))
1-element Array{Tuple{Union{Missing, Int64},Union{Missing, Int64}},1}:
 (missing, 1)
```

Assumes `left` and `right` are both strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first.
"""
struct OuterJoin{Left <: By, Right <: By} <: Join{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{OuterJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
eltype(::Type{OuterJoin{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey} =
    Tuple{Union{Missing, eltype(LeftIterator)}, Union{Missing, eltype(RightIterator)}}

compare(joined::OuterJoin, ::Nothing, ::Nothing) = nothing

export OuterJoin

IteratorSize(::Type{AType}) where {AType <: Union{InnerJoin, OuterJoin}} = SizeUnknown()

@inline next_left(joined::Union{InnerJoin, RightJoin}, left_history, right_history) =
    iterate(joined, (left_history, right_history, true, false))
@inline function next_left(joined::Union{LeftJoin, OuterJoin}, left_history, right_history)
    left_state, left_item, left_result = left_history
    (left_item, missing), (left_history, right_history, true, false)
end

@inline next_right(joined::Union{InnerJoin, LeftJoin}, left_history, right_history) =
    iterate(joined, (left_history, right_history, false, true))
@inline function next_right(joined::Union{RightJoin, OuterJoin}, left_history, right_history)
    right_state, right_item, right_result = right_history
    (missing, right_item), (left_history, right_history, false, true)
end

compare(joined::Union{InnerJoin, LeftJoin}, ::Nothing, right_history) = nothing
@inline function compare(joined::Union{LeftJoin, OuterJoin}, left_history, ::Nothing)
    left_state, left_item, left_result = left_history
    (left_item, missing), (left_history, nothing, true, false)
end

compare(joined::Union{InnerJoin, RightJoin}, left_history, ::Nothing) = nothing
@inline function compare(joined::Union{RightJoin, OuterJoin}, ::Nothing, right_history)
    right_state, right_item, right_result = right_history
    (missing, right_item), (nothing, right_history, false, true)
end

@inline function compare(joined, left_history, right_history)
    left_state, left_item, left_result = left_history
    right_state, right_item, right_result = right_history
    if isless(left_result, right_result)
        next_left(joined, left_history, right_history)
    elseif isless(right_result, left_result)
        next_right(joined, left_history, right_history)
    else
        (left_item, right_item), (left_history, right_history, true, true)
    end
end

iterate(::Join, ::Nothing) = nothing
iterate(joined::Join) = compare(joined,
    next_history(joined.left),
    next_history(joined.right)
)
iterate(joined::Join, (left_history, right_history, next_left, next_right)) =
    if next_left
        if next_right
            compare(joined,
                next_history(joined.left, left_history),
                next_history(joined.right, right_history)
            )
        else
            compare(joined,
                next_history(joined.left, left_history),
                right_history
            )
        end
    else
        if next_right
            compare(joined,
                left_history,
                next_history(joined.right, right_history)
            )
        else
            compare(joined, left_history, right_history)
        end
    end

"""
    distinct(it, key_function = identity)

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
function distinct(it, key_function = identity)
    result = unique(value, Enumerate(Generator(hash ∘ key_function, it)))
    view(it, mappedarray(key, result))
end

export distinct

# piracy
function copyto!(dictionary::Dict{Key, Value}, pairs::AbstractVector{Tuple{Key, Value}}) where {Key, Value}
    copyto_at!((a_key, a_value)) = dictionary[a_key] = a_value
    foreach(copyto_at!, dictionary)
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
