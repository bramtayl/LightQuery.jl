"""
    over(iterator, call)

Lazy `map` with argument order reversed.
"""
over(iterator, call) = Generator(call, iterator)
export over

"""
    when(iterator, call)

Lazy `filter` with argument order reversed.
"""
when(iterator, call) = Filter(call, iterator)
export when

state_to_index(::AbstractArray, state) = state[2]
state_to_index(::Array, state) = state - 1
state_to_index(filtered::Filter, state) = state_to_index(filtered.itr, state)
state_to_index(mapped::Generator, state) = state_to_index(mapped.iter, state)
"""
    Enumerated{Iterator}

Relies on the fact that iteration states can be converted to indices; thus, you might have to define `LightQuery.state_to_index` for unrecognized types. "Sees through" some iterators like `Filter`.

```jldoccall
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

Generalized sort. `keywords` will be passed to `sort!`; see the documentation there for options. See [`By`](@ref) for a way to explicitly mark that an object has been sorted. Relies on [`Enumerated`](@ref).

```jldoccall
julia> using LightQuery

julia> @name order([
            (item = "b", index = 2),
            (item = "a", index = 1)
        ], :index)
2-element view(::Array{Tuple{Tuple{LightQuery.Name{:item},String},Tuple{LightQuery.Name{:index},Int64}},1}, [2, 1]) with eltype Tuple{Tuple{LightQuery.Name{:item},String},Tuple{LightQuery.Name{:index},Int64}}:
 ((`item`, "a"), (`index`, 1))
 ((`item`, "b"), (`index`, 2))
```
"""
order(unordered, key; keywords...) =
    view(unordered, mappedarray(first,
        sort!(
            collect(Enumerated(Generator(key, unordered)));
            by = second,
            keywords...
        )
    ))
export order

# piracy
similar(old::Dict, ::Type{Pair{Key, Value}}) where {Key, Value} =
    Dict{Key, Value}(old)

function copyto!(dictionary::Dict{Key, Value}, pairs::AbstractVector{Pair{Key, Value}}) where {Key, Value}
    foreach(pair -> dictionary[pair.first] = pair.second, pairs)
    dictionary
end

struct Indexed{Iterator, Indices}
    iterator::Iterator
    indices::Indices
end
@propagate_inbounds getindex(indexed::Indexed, index) =
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
    (item.first => indexed.iterator[item.second]), state
end
function iterate(indexed::Indexed, state)
    item, state = @ifsomething iterate(indexed.indices, state)
    (item.first => indexed.iterator[item.second]), state
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
    indexed(iterator, key)

Index `iterator` by the results of `key`. Relies on [`Enumerated`](@ref).

```jldoccall
julia> using LightQuery

julia> result = @name indexed(
            [
                (item = "b", index = 2),
                (item = "a", index = 1)
            ],
            :index
        );

julia> result[1]
((`item`, "a"), (`index`, 1))
```
"""
function indexed(iterator, key)
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
export indexed

"""
    By(iterator, key)

Mark that `iterator` has been pre-sorted by `key`. For use with [`Group`](@ref) or
[`Join`](@ref).

```jldoccall
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

```jldoccall
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
2-element Array{Pair{Int64,SubArray{Tuple{Tuple{LightQuery.Name{:item},String},Tuple{LightQuery.Name{:group},Int64}},1,Array{Tuple{Tuple{LightQuery.Name{:item},String},Tuple{LightQuery.Name{:group},Int64}},1},Tuple{UnitRange{Int64}},true}},1}:
 1 => [((`item`, "a"), (`group`, 1)), ((`item`, "b"), (`group`, 1))]
 2 => [((`item`, "c"), (`group`, 2)), ((`item`, "d"), (`group`, 2))]
```
"""
Group(sorted::By) = Group(sorted.iterator, sorted.key)
IteratorSize(::Type{<: Group})  = SizeUnknown()
IteratorEltype(::Type{<: Group}) = EltypeUnknown()
iterate(grouped::Group, ::Nothing) = nothing
function iterate(grouped::Group, (state, left_index, last_result))
    item_state = iterate(grouped.ungrouped, state)
    if item_state === nothing
        last_result => (@inbounds view(
            grouped.ungrouped,
            left_index:length(grouped.ungrouped)
        )), nothing
    else
        item, state = item_state
        result = grouped.key(item)
        while isequal(result, last_result)
            item_state = iterate(grouped.ungrouped, state)
            if item_state === nothing
                return last_result => (@inbounds view(
                    grouped.ungrouped,
                    left_index:length(grouped.ungrouped)
                )), nothing
            else
                item, state = item_state
                result = grouped.key(item)
            end
        end
        right_index = state_to_index(grouped.ungrouped, state)
        last_result => (@inbounds view(
            grouped.ungrouped,
            left_index:right_index - 1
        )), (state, right_index, result)
    end
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

"""
    key(pair)

The `key` in a `key => value` `pair`.
"""
key(pair::Pair) = pair.first
export key

"""
    value(pair)

The `value` in a `key => value` `pair`.
"""
value(pair::Pair) = pair.second
export value

struct History{State, Item, Result}
    state::State
    item::Item
    result::Result
end
History(sorted::By, (item, state)) = History(state, item, sorted.key(item))
History(sorted::By, ::Nothing) = nothing
next_history(sorted::By, history::History) =
    History(sorted, iterate(sorted.iterator, history.state))
next_history(sorted::By) = History(sorted, iterate(sorted.iterator))
isless(history1::History, history2::History) =
    isless(history1.result, history2.result)
"""
    Join(left::By, right::By)

Find all pairs where `isequal(left.key(left.iterator), right.key(right.iterator))`.

```jldoccall Join
julia> using LightQuery

julia> @name Join(
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
6-element Array{Pair{Union{Missing, Tuple{Tuple{Name{:left},String},Tuple{Name{:index},Int64}}},Union{Missing, Tuple{Tuple{Name{:right},String},Tuple{Name{:index},Int64}}}},1}:
 ((`left`, "a"), (`index`, 1)) => ((`right`, "a"), (`index`, 1))
 ((`left`, "b"), (`index`, 2)) => missing
                       missing => ((`right`, "c"), (`index`, 3))
                       missing => ((`right`, "d"), (`index`, 4))
 ((`left`, "e"), (`index`, 5)) => missing
 ((`left`, "f"), (`index`, 6)) => ((`right`, "e"), (`index`, 6))
```

Assumes `left` and `right` are both strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first. For other join flavors, combine with [`when`](@ref). Make sure to annotate with [`Length`](@ref) if you know it.
"""
struct Join{Left <: By, Right <: By}
    left::Left
    right::Right
end
combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()
IteratorEltype(::Type{Join{By{It1, Key1}, By{It2, Key2}}}) where {It1, Key1, It2, Key2} =
    combine_iterator_eltype(IteratorEltype(It1), IteratorEltype(It2))
eltype(::Type{Join{By{It1, Key1}, By{It2, Key2}}}) where {It1, Key1, It2, Key2} =
    Pair{Union{Missing, eltype(It1)}, Union{Missing, eltype(It2)}}
IteratorSize(::Type{F}) where {F <: Join} = SizeUnknown()
handle_endings(::Nothing, ::Nothing) = nothing
handle_endings(::Nothing, right_history) =
    (missing => right_history.item), nothing
handle_endings(left_history, ::Nothing) =
    (left_history.item => missing), nothing
handle_endings(left_history, right_history) =
    if isless(left_history, right_history)
        (left_history.item => missing),
        (left_history, right_history, true, false)
    elseif isless(right_history, left_history)
        (missing => right_history.item,
        (left_history, right_history, false, true))
    else
        (left_history.item => right_history.item),
        (left_history, right_history, true, true)
    end
iterate(::Join, ::Nothing) = nothing
function iterate(joined::Join)
    left_history = next_history(joined.left)
    right_history = next_history(joined.right)
    handle_endings(left_history, right_history)
end
function iterate(joined::Join, (left_history, right_history, next_left, next_right))
    if next_left
        left_history = next_history(joined.left, left_history)
    end
    if next_right
        right_history = next_history(joined.right, right_history)
    end
    handle_endings(left_history, right_history)
end
export Join

"""
    Length(fixed, length)

Allow optimizations based on length. Especially useful after [`Join`](@ref) and before [`make_columns`](@ref).

```jldoccall
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
@propagate_inbounds view(mapped::Generator, index...) =
    Generator(mapped.f, view(mapped.iter, index...))
@propagate_inbounds view(filtered::Filter, index...) =
    view(filtered.itr, index...)
@propagate_inbounds getindex(mapped::Generator, index...) =
    mapped.f(mapped.iter[index...])
