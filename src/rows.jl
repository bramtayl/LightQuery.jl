state_to_index(::AbstractArray, state) = value(state)
state_to_index(::Array, state) = state - 1
state_to_index(filtered::Filter, state) = state_to_index(filtered.itr, state)
state_to_index(mapped::Generator, state) = state_to_index(mapped.iter, state)
state_to_index(zipped::Zip, state) =
    state_to_index(first(zipped.is), first(state))

"""
    Enumerated{Iterator}

Relies on the fact that iteration states can be converted to indices; thus, you might have to define `LightQuery.state_to_index` for unrecognized types. "Sees through" some iterators like `Filter`.

```jldoctest
julia> using LightQuery

julia> collect(Enumerated(when([4, 3, 2, 1], iseven)))
2-element Array{Tuple{Int64,Int64},1}:
 (1, 4)
 (3, 2)
```
"""
struct Enumerated{Iterator}
    iterator::Iterator
end

IteratorEltype(::Type{Enumerated{Iterator}}) where {Iterator} =
    IteratorEltype(Iterator)
eltype(::Type{Enumerated{Iterator}}) where {Iterator} =
    Tuple{Int, eltype(Iterator)}

IteratorSize(::Type{Enumerated{Iterator}}) where {Iterator} =
    IteratorSize(Iterator)
length(enumerated::Enumerated) = length(enumerated.iterator)
size(enumerated::Enumerated) = size(enumerated.iterator)
axes(enumerated::Enumerated) = axes(enumerated.iterator)

function iterate(enumerated::Enumerated)
    item, state = @ifsomething iterate(enumerated.iterator)
    (state_to_index(enumerated.iterator, state), item), state
end
function iterate(enumerated::Enumerated, state)
    item, state = @ifsomething iterate(enumerated.iterator, state)
    (state_to_index(enumerated.iterator, state), item), state
end
export Enumerated

"""
    order(unordered, key; keywords...)

Generalized sort. `keywords` will be passed to `sort!`; see the documentation there for options. Use [`By`](@ref) to mark that an object has been sorted. Relies on [`Enumerated`](@ref).

```jldoctest
julia> using LightQuery

julia> @name order([
            (item = "b", index = 2),
            (item = "a", index = 1)
        ], :index)
2-element view(::Array{Tuple{Tuple{Name{:item},String},Tuple{Name{:index},Int64}},1}, [2, 1]) with eltype Tuple{Tuple{Name{:item},String},Tuple{Name{:index},Int64}}:
 ((`item`, "a"), (`index`, 1))
 ((`item`, "b"), (`index`, 2))
```
"""
order(unordered, key; keywords...) =
    view(unordered, mappedarray(first,
        sort!(
            collect(Enumerated(Generator(key, unordered)));
            by = value,
            keywords...
        )
    ))
export order

struct Indexed{Iterator, Indices}
    iterator::Iterator
    indices::Indices
end

@inline getindex(indexed::Indexed, index) =
    indexed.iterator[indexed.indices[index]]

function get(indexed::Indexed, index, default)
    inner_index = get(indexed.indices, index, nothing)
    if inner_index === nothing
        default
    else
        indexed.iterator[inner_index]
    end
end

haskey(indexed::Indexed, index) = haskey(indexed.indices, index)

function iterate(indexed::Indexed)
    item, state = @ifsomething iterate(indexed.indices)
    (key(item) => indexed.iterator[value(item)]), state
end
function iterate(indexed::Indexed, state)
    item, state = @ifsomething iterate(indexed.indices, state)
    (key(item) => indexed.iterator[value(item)]), state
end

IteratorSize(::Type{Indexed{Iterator, Indices}}) where {Iterator, Indices} =
    IteratorSize(Indices)
length(indexed::Indexed) = length(indexed.indices)
size(indexed::Indexed) = size(indexed.indices)
axes(indexed::Indexed) = axes(indexed.indices)

IteratorEltype(::Type{Indexed{Iterator, Indices}}) where {Iterator, Indices} =
    combine_iterator_eltype(IteratorEltype(Iterator), IteratorEltype(Indices))
eltype(::Type{Indexed{Iterator, Indices}}) where {Iterator, Indices} =
    Pair{keytype(Indices), Union{Missing, eltype(Iterator)}}

"""
    index(iterator, key)

Index `iterator` by the results of `key`. Relies on [`Enumerated`](@ref).

```jldoctest
julia> using LightQuery

julia> result = @name index(
            [
                (item = "b", index = 2),
                (item = "a", index = 1)
            ],
            :index
        );

julia> result[2]
((`item`, "b"), (`index`, 2))
```
"""
function index(iterator, key)
    Indexed(iterator, collect_similar(
        Dict{Union{}, Union{}}(),
        Generator(
            index_item -> begin
                index, item = index_item
                key(item) => index
            end,
            Enumerated(iterator)
        )
    ))
end
export index

"""
    By(iterator, key)

Mark that `iterator` has been pre-sorted by `key`. Use with [`Group`](@ref) or
[`InnerJoin`](@ref).

```jldoctest
julia> using LightQuery

julia> @name By([
            (item = "a", index = 1),
            (item = "b", index = 2)
        ], :index);
```
"""
struct By{Iterator, Key}
    iterator::Iterator
    key::Key
end
export By

struct Group{Iterator, Key}
    ungrouped::Iterator
    key::Key
end

"""
    Group(ungrouped::By)

Group consecutive keys in `ungrouped`. Requires a presorted object (see [`By`](@ref)). Relies on [`Enumerated`](@ref).

```jldoctest
julia> using LightQuery

julia> @name Group(By(
            [
                (item = "a", group = 1),
                (item = "b", group = 1),
                (item = "c", group = 2),
                (item = "d", group = 2)
            ],
            :group
        )) |>
        collect
2-element Array{Tuple{Int64,SubArray{Tuple{Tuple{Name{:item},String},Tuple{Name{:group},Int64}},1,Array{Tuple{Tuple{Name{:item},String},Tuple{Name{:group},Int64}},1},Tuple{UnitRange{Int64}},true}},1}:
 (1, [((`item`, "a"), (`group`, 1)), ((`item`, "b"), (`group`, 1))])
 (2, [((`item`, "c"), (`group`, 2)), ((`item`, "d"), (`group`, 2))])
```
"""
Group(sorted::By) = Group(sorted.iterator, sorted.key)

IteratorSize(::Type{<: Group})  = SizeUnknown()
IteratorEltype(::Type{<: Group}) = EltypeUnknown()

function last_group(grouped, left_index, last_result)
    (last_result, (@inbounds view(
        grouped.ungrouped,
        left_index:length(grouped.ungrouped)
    ))), nothing
end

function next_result(grouped, item_state)
    item, state = item_state
    result = grouped.key(item)
    result, state
end

iterate(grouped::Group, ::Nothing) = nothing
function iterate(grouped::Group, (state, left_index, last_result))
    item_state = iterate(grouped.ungrouped, state)
    if item_state === nothing
        return last_group(grouped, left_index, last_result)
    end
    result, state = next_result(grouped, item_state)
    while isequal(result, last_result)
        item_state = iterate(grouped.ungrouped, state)
        if item_state === nothing
            return last_group(grouped, left_index, last_result)
        end
        result, state = next_result(grouped, item_state)
    end
    right_index = state_to_index(grouped.ungrouped, state)
    return (last_result, (@inbounds view(
        grouped.ungrouped,
        left_index:right_index - 1
    ))), (state, right_index, result)
end
function iterate(grouped::Group)
    item, state = @ifsomething iterate(grouped.ungrouped)
    iterate(grouped, (
        state,
        state_to_index(grouped.ungrouped, state),
        grouped.key(item)
    ))
end
export Group


abstract type Join{Left <: By, Right <: By} end

combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()

function next_history(side)
    item, state = @ifsomething iterate(side.iterator)
    result = side.key(item)
    (state, item, result)
end
function next_history(side, (state, item, result))
    new_item, new_state = @ifsomething iterate(side.iterator, state)
    new_result = side.key(new_item)
    (new_state, new_item, new_result)
end

iterate(::Join, ::Nothing) = nothing
iterate(joined::Join) = compare(
    joined,
    next_history(joined.left),
    next_history(joined.right)
)

function iterate(joined::Join, (left_history, right_history, next_left, next_right))
    if next_left
        if next_right
            compare(
                joined,
                next_history(joined.left, left_history),
                next_history(joined.right, right_history)
            )
        else
            compare(
                joined,
                next_history(joined.left, left_history),
                right_history
            )
        end
    else
        if next_right
            compare(
                joined,
                left_history,
                next_history(joined.right, right_history)
            )
        else
            error("Unreachable")
        end
    end
end

"""
    InnerJoin(left::By, right::By) <: Join{Left, Right}

Find all pairs where `isequal(left.key(left.iterator), right.key(right.iterator))`.

```jldoctest InnerJoin
julia> using LightQuery

julia> @name InnerJoin(
            By(
                [
                    (left = "a", index = 1),
                    (left = "b", index = 2),
                    (left = "e", index = 5),
                    (left = "f", index = 6)
                ],
                :index
            ),
            By(
                [
                    (right = "a", index = 1),
                    (right = "c", index = 3),
                    (right = "d", index = 4),
                    (right = "e", index = 6)
                ],
                :index
            )
        ) |>
        collect
2-element Array{Tuple{Tuple{Tuple{Name{:left},String},Tuple{Name{:index},Int64}},Tuple{Tuple{Name{:right},String},Tuple{Name{:index},Int64}}},1}:
 (((`left`, "a"), (`index`, 1)), ((`right`, "a"), (`index`, 1)))
 (((`left`, "f"), (`index`, 6)), ((`right`, "e"), (`index`, 6)))
```

Assumes `left` and `right` are both strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first. Annotate with [`Length`](@ref) if you know it.
"""
struct InnerJoin{Left <: By, Right <: By} <: Join{Left, Right}
    left::Left
    right::Right
end

IteratorEltype(::Type{InnerJoin{By{It1, Key1}, By{It2, Key2}}}) where {It1, Key1, It2, Key2} =
    combine_iterator_eltype(IteratorEltype(It1), IteratorEltype(It2))
eltype(::Type{InnerJoin{By{It1, Key1}, By{It2, Key2}}}) where {It1, Key1, It2, Key2} =
    Tuple{eltype(It1), eltype(It2)}

IteratorSize(::Type{AType}) where {AType <: InnerJoin} = SizeUnknown()

function compare(joined::InnerJoin, left_history, right_history)
    left_state, left_item, left_result = left_history
    right_state, right_item, right_result = right_history
    if isless(left_result, right_result)
        iterate(joined, (left_history, right_history, true, false))
    elseif isless(right_result, left_result)
        iterate(joined, (left_history, right_history, false, true))
    else
        (left_item, right_item), (left_history, right_history, true, true)
    end
end
compare(joined::InnerJoin, ::Nothing, ::Nothing) = nothing
compare(joined::InnerJoin, (left_item, left_state), ::Nothing) = nothing
compare(joined::InnerJoin, ::Nothing, (right_item, right_state)) = nothing

export InnerJoin

"""
    Length(iterator, new_length)

Allow optimizations based on length.

```jldoctest
julia> using LightQuery

julia> @> Filter(iseven, 1:4) |>
        Length(_, 2) |>
        collect
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

# piracy
function copyto!(dictionary::Dict{Key, Value}, pairs::AbstractVector{Tuple{Key, Value}}) where {Key, Value}
    foreach(pair -> dictionary[key(pair)] = value(pair), pairs)
    dictionary
end
similar(old::Dict, ::Type{Tuple{Key, Value}}) where {Key, Value} =
    Dict{Key, Value}(old)

@inline getindex(mapped::Generator, index...) = mapped.f(mapped.iter[index...])
@inline view(mapped::Generator, index...) =
    Generator(mapped.f, view(mapped.iter, index...))

@inline getindex_reverse(index, column) = column[index...]
@inline getindex(zipped::Zip, index...) =
    partial_map(getindex_reverse, index, zipped.is)
@inline view_reverse(index, column) = view(column, index...)
@inline view(zipped::Zip, index...) =
    zip(partial_map(view_reverse, index, zipped.is)...)

@inline view(filtered::Filter, index...) = view(filtered.itr, index...)

# identical to Base except key, value
@inline function iterate(g::Generator, s...)
    y = iterate(g.iter, s...)
    y === nothing && return nothing
    return (g.f(key(y)), value(y))
end
