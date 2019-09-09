"""
    Enumerate{Unenumerated}

"Sees through" most iterators into their `parent`.

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

function IteratorEltype(::Type{Enumerate{Unenumerated}}) where {Unenumerated}
    EltypeUnknown()
end
function IteratorSize(::Type{Enumerate{Unenumerated}}) where {Unenumerated}
    IteratorSize(Unenumerated)
end
function length(enumerated::Enumerate)
    length(enumerated.unenumerated)
end
function size(enumerated::Enumerate)
    size(enumerated.unenumerated)
end
function axes(enumerated::Enumerate)
    axes(enumerated.unenumerated)
end

function iterate(enumerated::Enumerate)
    item, state = @ifsomething iterate(enumerated.unenumerated)
    (make_index(enumerated.unenumerated, state), item), state
end
function iterate(enumerated::Enumerate, state)
    item, state = @ifsomething iterate(enumerated.unenumerated, state)
    (make_index(enumerated.unenumerated, state), item), state
end
export Enumerate

struct OrderView{Unordered, IndexKeys}
    unordered::Unordered
    index_keys::IndexKeys
end

function parent(order_view::OrderView)
    order_view.index_keys
end

function IteratorEltype(::Type{OrderView{Unordered, IndexKeys}}) where {Unordered, IndexKeys}
    IteratorEltype(Unordered)
end
function eltype(::Type{OrderView{Unordered, IndexKeys}}) where  {Unordered, IndexKeys}
    eltype(Unordered)
end

function IteratorSize(::Type{OrderView{Unordered, IndexKeys}}) where {Unordered, IndexKeys}
    IteratorSize(IndexKeys)
end
function axes(order_view::OrderView, dimensions...)
    axes(order_view.index_keys, dimensions...)
end
function size(order_view::OrderView, dimensions...)
    size(order_view.index_keys, dimensions...)
end
function length(order_view::OrderView)
    length(order_view.index_keys)
end
function ndims(order_view::OrderView)
    ndims(order_view.index_keys)
end

@propagate_inbounds function getindex(order_view::OrderView, index::Int...)
    order_view.unordered[key(order_view.index_keys[index...])]
end

@propagate_inbounds function view(order_view::OrderView, indices...)
    OrderView(order_view.unordered, view(order_view.index_keys, indices...))
end

function iterate(order_view::OrderView, state...)
    index_key, state = @ifsomething iterate(order_view.index_keys, state...)
    order_view.unordered[key(index_key)], state
end

"""
    order(unordered, key_function; keywords...)

Generalized sort. `keywords` will be passed to `sort!`; see the documentation there for options. Use [`By`](@ref) to mark that an object has been sorted. If the results of `key_function` are type unstable, consider using `hash ∘ key_function` instead.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> collect(@inferred order([-2, 1], abs))
2-element Array{Int64,1}:
  1
 -2
```
"""
function order(unordered, key_function; keywords...)
    index_keys = collect(Enumerate(over(unordered, key_function)))
    sort!(index_keys, by = value; keywords...)
    OrderView(unordered, index_keys)
end
export order

struct Backwards{Increasing}
    increasing::Increasing
end

"""
    backwards(something)

Reverse sorting order.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> collect(@inferred order([1, -2], backwards))
2-element Array{Int64,1}:
  1
 -2
```
"""
function backwards(something)
    Backwards(something)
end
export backwards

function show(io::IO, descending::Backwards)
    print(io, "Backwards($(descending.increasing))")
end

function isless(descending_1::Backwards, descending_2::Backwards)
    isless(descending_2.increasing, descending_1.increasing)
end

struct Indexed{Key, Value, Unindexed, KeyToIndex} <: AbstractDict{Key, Value}
    unindexed::Unindexed
    key_to_index::KeyToIndex
end

function Indexed{Key, Value}(unindexed::Unindexed, key_to_index::KeyToIndex) where {Key, Value, Unindexed, KeyToIndex}
    Indexed{Key, Value, Unindexed, KeyToIndex}(unindexed, key_to_index)
end

@propagate_inbounds function getindex(indexed::Indexed, a_key)
    indexed.unindexed[indexed.key_to_index[a_key]]
end

function get(indexed::Indexed, a_key, default)
    index = get(indexed.key_to_index, a_key, nothing)
    if index === nothing
        default
    else
        indexed.unindexed[index]
    end
end

function haskey(indexed::Indexed, a_key)
    haskey(indexed.key_to_index, a_key)
end

function iterate(indexed::Indexed, state...)
    key_index, next_state = @ifsomething iterate(indexed.key_to_index, state...)
    (key(key_index) => indexed.unindexed[value(key_index)]), next_state
end

function IteratorSize(::Type{Indexed{Unindexed, KeyToIndex}}) where {Unindexed, KeyToIndex}
    IteratorSize(KeyToIndex)
end
function length(indexed::Indexed)
    length(indexed.key_to_index)
end
function size(indexed::Indexed)
    size(indexed.key_to_index)
end
function axes(indexed::Indexed)
    axes(indexed.key_to_index)
end

function IteratorEltype(::Type{Indexed{Unindexed, KeyToIndex}}) where {Unindexed, KeyToIndex}
    combine_iterator_eltype(IteratorEltype(Unindexed), IteratorEltype(KeyToIndex))
end
function eltype(::Type{Indexed{Unindexed, KeyToIndex}}) where {Unindexed, KeyToIndex}
    Pair{keytype(KeyToIndex), eltype(Unindexed)}
end

function key_index(key_function, (index, item))
    key_function(item) => index
end

"""
    index(unindexed, key_function)

Index `unindexed` by the results of `key_function`. Results of `key_function` must be unique.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> result = @inferred index([-2, 1], abs)
LightQuery.Indexed{Int64,Int64,Array{Int64,1},Dict{Int64,Int64}} with 2 entries:
  2 => -2
  1 => 1

julia> @inferred result[2]
-2
```
"""
function index(unindexed, key_function)
    key_to_index = collect_similar(
        Dict{Union{}, Union{}}(),
        Generator(let key_function = key_function
            index_item -> key_index(key_function, index_item)
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

Group consecutive keys in `ungrouped`.

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

Requires a presorted object (see [`By`](@ref)); [`order`](@ref) first if not.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> first_group =
        @> [2, 1, 2, 1] |>
        order(_, identity) |>
        Group(By(_, identity)) |>
        first;

julia> key(first_group)
1

julia> collect(value(first_group))
2-element Array{Int64,1}:
 1
 1
```
"""
function Group(sorted::By)
    Group(sorted.sorted, sorted.key_function)
end

function IteratorSize(::Type{<: Group})
    SizeUnknown()
end
function IteratorEltype(::Type{<: Group})
    EltypeUnknown()
end

function get_group(group, state, old_key_result, old_left_index,
    right_index = last_index(group.ungrouped),
    new_left_index = old_left_index,
    new_key_result = old_key_result,
    is_last = true
)
    (old_key_result, (@inbounds view(
        group.ungrouped,
        old_left_index:right_index,
    ))), (state, new_left_index, new_key_result, is_last)
end

function iterate(group::Group, (state, old_left_index, old_key_result, is_last))
    if is_last
        nothing
    else
        item_state = iterate(group.ungrouped, state)
        if item_state === nothing
            return get_group(group, state, old_key_result, old_left_index)
        end
        item, state = item_state
        new_key_result = group.key_function(item)
        while isequal(new_key_result, old_key_result)
            item_state = iterate(group.ungrouped, state)
            if item_state === nothing
                return get_group(group, state, old_key_result, old_left_index)
            end
            item, state = item_state
            new_key_result = group.key_function(item)
        end
        new_left_index = make_index(group.ungrouped, state)
        get_group(group, state, old_key_result, old_left_index,
            previous_index(group.ungrouped, new_left_index),
            new_left_index,
            new_key_result,
            false
        )
    end
end
function iterate(group::Group)
    item, state = @ifsomething iterate(group.ungrouped)
    iterate(group, (
        state,
        make_index(group.ungrouped, state),
        group.key_function(item),
        false
    ))
end
export Group

abstract type Mix{Left <: By, Right <: By} end

function combine_iterator_eltype(::HasEltype, ::HasEltype)
    HasEltype()
end
function combine_iterator_eltype(x, y)
    EltypeUnknown()
end

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

function IteratorEltype(::Type{InnerMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
end
function eltype(::Type{InnerMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    Tuple{eltype(LeftIterator), eltype(RightIterator)}
end

function compare(mixed::InnerMix, ::Nothing, ::Nothing)
    nothing
end

struct LeftMix{Left <: By, Right <: By} <: Mix{Left, Right}
    left::Left
    right::Right
end

function IteratorEltype(::Type{LeftMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
end
function eltype(::Type{LeftMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    Tuple{eltype(LeftIterator), Union{Missing, eltype(RightIterator)}}
end

function IteratorSize(::Type{LeftMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    IteratorSize(LeftIterator)
end
function size(mixed::LeftMix)
    size(mixed.left.sorted)
end
function length(mixed::LeftMix)
    length(mixed.left.sorted)
end
function axes(mixed::LeftMix)
    axes(mixed.left.sorted)
end

function compare(mixed::LeftMix, ::Nothing, ::Nothing)
    nothing
end

struct RightMix{Left <: By, Right <: By} <: Mix{Left, Right}
    left::Left
    right::Right
end

function IteratorEltype(::Type{RightMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
end
function eltype(::Type{RightMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    Tuple{Union{Missing, eltype(LeftIterator)}, eltype(RightIterator)}
end

function IteratorSize(::Type{RightMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    IteratorSize(RightIterator)
end
function size(mixed::RightMix)
    size(mixed.right.sorted)
end
function length(mixed::RightMix)
    length(mixed.right.sorted)
end
function axes(mixed::RightMix)
    axes(mixed.right.sorted)
end

function compare(mixed::RightMix, ::Nothing, ::Nothing)
    nothing
end

struct OuterMix{Left <: By, Right <: By} <: Mix{Left, Right}
    left::Left
    right::Right
end

function IteratorEltype(::Type{OuterMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    combine_iterator_eltype(IteratorEltype(LeftIterator), IteratorEltype(RightIterator))
end
function eltype(::Type{OuterMix{By{LeftIterator, LeftKey}, By{RightIterator, RightKey}}}) where {LeftIterator, LeftKey, RightIterator, RightKey}
    Tuple{Union{Missing, eltype(LeftIterator)}, Union{Missing, eltype(RightIterator)}}
end

function compare(mixed::OuterMix, ::Nothing, ::Nothing)
    nothing
end

function IteratorSize(::Type{AType}) where {AType <: Union{InnerMix, OuterMix}}
    SizeUnknown()
end

@inline function next_left(mixed::Union{InnerMix, RightMix}, left_history, right_history)
    iterate(mixed, (left_history, right_history, true, false))
end
@inline function next_left(mixed::Union{LeftMix, OuterMix}, left_history, right_history)
    left_state, left_item, left_key_result = left_history
    (left_item, missing), (left_history, right_history, true, false)
end

@inline function next_right(mixed::Union{InnerMix, LeftMix}, left_history, right_history)
    iterate(mixed, (left_history, right_history, false, true))
end
@inline function next_right(mixed::Union{RightMix, OuterMix}, left_history, right_history)
    right_state, right_item, right_key_result = right_history
    (missing, right_item), (left_history, right_history, false, true)
end

function compare(mixed::Union{InnerMix, LeftMix}, ::Nothing, right_history)
    nothing
end
@inline function compare(mixed::Union{LeftMix, OuterMix}, left_history, ::Nothing)
    left_state, left_item, left_key_result = left_history
    (left_item, missing), (left_history, nothing, true, false)
end

function compare(mixed::Union{InnerMix, RightMix}, left_history, ::Nothing)
    nothing
end
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

function iterate(::Mix, ::Nothing)
    nothing
end
function iterate(mixed::Mix)
    compare(mixed,
        next_history(mixed.left),
        next_history(mixed.right)
    )
end
function iterate(mixed::Mix, (left_history, right_history, next_left, next_right))
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
end

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
function mix(::Name{:inner}, left, right)
    InnerMix(left, right)
end

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
function mix(::Name{:left}, left, right)
    LeftMix(left, right)
end

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
function mix(::Name{:right}, left, right)
    RightMix(left, right)
end

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
function mix(::Name{:outer}, left, right)
    OuterMix(left, right)
end

export mix

# piracy
function copyto!(dictionary::Dict{Key, Value}, pairs::AbstractVector{Tuple{Key, Value}}) where {Key, Value}
    foreach(let dictionary = dictionary
        ((a_key, a_value),) -> dictionary[a_key] = a_value
    end, dictionary)
    nothing
end
function similar(old::Dict, ::Type{Tuple{Key, Value}}) where {Key, Value}
    Dict{Key, Value}(old)
end

"""
    Length(iterator, new_length)

Allow optimizations based on length.

```jldoctest
julia> using LightQuery

julia> collect(Length(when(1:4, iseven), 2))
2-element Array{Int64,1}:
 2
 4
```
"""
struct Length{Iterator}
    iterator::Iterator
    new_length::Int
end
IteratorEltype(::Type{Length{Iterator}}) where {Iterator} =
    IteratorEltype(Iterator)
eltype(fixed::Length) = eltype(fixed.iterator)
IteratorLength(::Type{T}) where {T <: Length} = HasLength()
length(fixed::Length) = fixed.new_length
iterate(fixed::Length) = iterate(fixed.iterator)
iterate(fixed::Length, state) = iterate(fixed.iterator, state)
export Length
