"""
    over(it, call)

Lazy `map` with argument order reversed.
"""
over(it, call) = Generator(call, it)
export over

"""
    when(it, call)

Lazy `filter` with argument order reversed.
"""
when(it, call) = Filter(call, it)
export when


state_to_index(it::AbstractArray, state) = state[2]
state_to_index(it::Array, state::Int) = state - 1
state_to_index(it::Filter, state) = state_to_index(it.itr, state)
state_to_index(it::Generator, state) = state_to_index(it.iter, state)
"""
    Enumerated{It}

Relies on the fact that iteration states can be converted to indices; thus, you might have to define `LightQuery.state_to_index` for unrecognized types. "Sees through" some iterators like `Filter`.

```jldoctest
julia> using LightQuery

julia> collect(Enumerated(when([4, 3, 2, 1], iseven)))
2-element Array{Tuple{Int64,Int64},1}:
 (1, 4)
 (3, 2)
```
"""
struct Enumerated{It}
    it::It
end
IteratorEltype(::Type{Enumerated{It}}) where {It} = IteratorEltype(It)
eltype(::Type{Enumerated{It}}) where {It} = Tuple{Int, eltype(It)}
IteratorSize(::Type{Enumerated{It}}) where {It} = IteratorSize(It)
length(it::Enumerated) = length(it.it)
size(it::Enumerated) = size(it.it)
axes(it::Enumerated) = axes(it.it)
function iterate(it::Enumerated)
    item, state = @ifsomething iterate(it.it)
    (state_to_index(it.it, state), item), state
end
function iterate(it::Enumerated, state)
    item, state = @ifsomething iterate(it.it, state)
    (state_to_index(it.it, state), item), state
end
export Enumerated

"""
    order(it, call; keywords...)

Generalized sort. `keywords` will be passed to `sort!`; see the documentation there for options. See [`By`](@ref) for a way to explicitly mark that an object has been sorted. Relies on [`Enumerated`](@ref).

```jldoctest
julia> using LightQuery

julia> @name order([
            (item = "b", index = 2),
            (item = "a", index = 1)
        ], :index)
2-element view(::Array{Tuple{Tuple{LightQuery.Name{:item},String},Tuple{LightQuery.Name{:index},Int64}},1}, [2, 1]) with eltype Tuple{Tuple{LightQuery.Name{:item},String},Tuple{LightQuery.Name{:index},Int64}}:
 ((item, "a"), (index, 1))
 ((item, "b"), (index, 2))
```
"""
order(it, call; keywords...) =
    view(it, mappedarray(first,
        sort!(collect(Enumerated(Generator(call, it))), by = last; keywords...)
    ))
export order

function similar(old::Dict, ::Type{Pair{Key, Value}}) where {Key, Value}
    Dict{Key, Value}(old)
end
function copyto!(dictionary::Dict{Key, Value}, array::AbstractVector{Pair{Key, Value}}) where {Key, Value}
    for item in array
        dictionary[item.first] = item.second
    end
    dictionary
end

struct Indexed{It, Indices}
    it::It
    indices::Indices
end
@propagate_inbounds getindex(it::Indexed, index) = it.it[it.indices[index]]
haskey(it::Indexed, index) = haskey(it.indices, index)
function iterate(it::Indexed)
    item, state = @ifsomething iterate(it.indices)
    (item.first => it.it[item.second]), state
end
function iterate(it::Indexed, state)
    item, state = @ifsomething iterate(it.indices, state)
    (item.first => it.it[item.second]), state
end
IteratorSize(::Type{Indexed{It, Indices}}) where {It, Indices} =
    IteratorSize(Indices)
length(it::Indexed) = length(it.indices)
size(it::Indexed) = size(it.indices)
axes(it::Indexed) = axes(it.indices)
IteratorEltype(::Type{Indexed{It, Indices}}) where {It, Indices} =
    combine_iterator_eltype(IteratorEltype(It), IteratorEltype(Indices))
eltype(::Type{Indexed{It, Indices}}) where {It, Indices} =
    Pair{keytype(Indices), Union{Missing, eltype(It)}}
"""
    indexed(it, call)

Index `it` by the results of `call`. Relies on [`Enumerated`](@ref).

```jldoctest
julia> using LightQuery

julia> result = @name indexed(
            [
                (item = "b", index = 2),
                (item = "a", index = 1)
            ],
            :index
        );

julia> result[1]
((item, "a"), (index, 1))
```
"""
function indexed(it, call)
    Indexed(it, collect_similar(
        Dict{Union{}, Union{}}(),
        Generator(
            index_item -> begin
                index, item = index_item
                call(item) => index
            end,
            Enumerated(it)
        )
    ))
end
export indexed

"""
    By(it, call)

Mark that `it` has been pre-sorted by `call`. For use with [`Group`](@ref) or
[`Join`](@ref).

```jldoctest
julia> using LightQuery

julia> @name By([
            (item = "a", index = 1),
            (item = "b", index = 2)
        ], :index);
```
"""
struct By{It, Call}
    it::It
    call::Call
end
export By


struct Group{It, Call}
    it::It
    call::Call
end
"""
    Group(it::By)

Group consecutive keys in `it`. Requires a presorted object (see [`By`](@ref)). Relies on [`Enumerated`](@ref).

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
2-element Array{Pair{Int64,SubArray{Tuple{Tuple{LightQuery.Name{:item},String},Tuple{LightQuery.Name{:group},Int64}},1,Array{Tuple{Tuple{LightQuery.Name{:item},String},Tuple{LightQuery.Name{:group},Int64}},1},Tuple{UnitRange{Int64}},true}},1}:
 1 => [((item, "a"), (group, 1)), ((item, "b"), (group, 1))]
 2 => [((item, "c"), (group, 2)), ((item, "d"), (group, 2))]
```
"""
Group(it::By) = Group(it.it, it.call)
IteratorSize(::Type{<: Group})  = SizeUnknown()
IteratorEltype(::Type{<: Group}) = EltypeUnknown()
iterate(it::Group, ::Nothing) = nothing
function iterate(it::Group, (state, left_index, last_result))
    item_state = iterate(it.it, state)
    if item_state === nothing
        last_result => (@inbounds view(it.it, left_index:length(it.it))), nothing
    else
        item, state = item_state
        result = it.call(item)
        while isequal(result, last_result)
            item_state = iterate(it.it, state)
            if item_state === nothing
                return last_result => (@inbounds view(it.it, left_index:length(it.it))), nothing
            else
                item, state = item_state
                result = it.call(item)
            end
        end
        right_index = state_to_index(it.it, state)
        last_result => (@inbounds view(it.it, left_index:right_index - 1)), (state, right_index, result)
    end
end
function iterate(it::Group)
    item, state = @ifsomething iterate(it.it)
    iterate(it, (state, state_to_index(it.it, state), it.call(item)))
end
export Group

"""
    key(it)

The `key` in a `key => value` pair.
"""
key(it::Pair) = it.first
export key

"""
    value(it)

The `value` in a `key => value` pair.
"""
value(it::Pair) = it.second
export value

struct History{State, Item, Result}
    state::State
    item::Item
    result::Result
end
History(it::By, (item, state)) = History(state, item, it.call(item))
History(it::By, ::Nothing) = nothing
next_history(it::By, history::History) =
    History(it, iterate(it.it, history.state))
next_history(it::By) = History(it, iterate(it.it))
isless(history1::History, history2::History) =
    isless(history1.result, history2.result)
"""
    Join(left::By, right::By)

Find all pairs where `isequal(left.call(left.it), right.call(right.it))`.

```jldoctest Join
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
 ((left, "a"), (index, 1)) => ((right, "a"), (index, 1))
 ((left, "b"), (index, 2)) => missing
                   missing => ((right, "c"), (index, 3))
                   missing => ((right, "d"), (index, 4))
 ((left, "e"), (index, 5)) => missing
 ((left, "f"), (index, 6)) => ((right, "e"), (index, 6))
```

Assumes `left` and `right` are both strictly sorted (no repeats). If there are repeats, [`Group`](@ref) first. For other join flavors, combine with [`when`](@ref). Make sure to annotate with [`Length`](@ref) if you know it.
"""
struct Join{Left <: By, Right <: By}
    left::Left
    right::Right
end
combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()
IteratorEltype(::Type{Join{By{It1, Call1}, By{It2, Call2}}}) where {It1, Call1, It2, Call2} =
    combine_iterator_eltype(IteratorEltype(It1), IteratorEltype(It2))
eltype(::Type{Join{By{It1, Call1}, By{It2, Call2}}}) where {It1, Call1, It2, Call2} =
    Pair{Union{Missing, eltype(It1)}, Union{Missing, eltype(It2)}}
IteratorSize(::Type{F}) where {F <: Join} = SizeUnknown()
full_dispatch(it, ::Nothing, ::Nothing) = nothing
full_dispatch(it, ::Nothing, right_history) =
    (missing => right_history.item), nothing
full_dispatch(it, left_history, ::Nothing) =
    (left_history.item => missing), nothing
full_dispatch(it, left_history, right_history) =
    if isless(left_history, right_history)
        (left_history.item => missing), (left_history, right_history, true, false)
    elseif isless(right_history, left_history)
        (missing => right_history.item, (left_history, right_history, false, true))
    else
    (left_history.item => right_history.item), (left_history, right_history, true, true)
    end
iterate(it::Join, ::Nothing) = nothing
function iterate(it::Join)
    left_history = next_history(it.left)
    right_history = next_history(it.right)
    full_dispatch(it, left_history, right_history)
end
function iterate(it::Join, (left_history, right_history, next_left, next_right))
    if next_left
        left_history = next_history(it.left, left_history)
    end
    if next_right
        right_history = next_history(it.right, right_history)
    end
    full_dispatch(it, left_history, right_history)
end
export Join

"""
    Length(it, length)

Allow optimizations based on length. Especially useful after [`Join`](@ref) and before [`make_columns`](@ref).

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
struct Length{It}
    it::It
    length::Int
end
IteratorEltype(::Type{Length{It}}) where {It} = IteratorEltype(It)
eltype(it::Length) = eltype(it.it)
IteratorLength(::Type{T}) where {T <: Length} = HasLength()
length(it::Length) = it.length
iterate(it::Length) = iterate(it.it)
iterate(it::Length, state) = iterate(it.it, state)
export Length

# piracy
@propagate_inbounds view(it::Generator, index...) =
    Generator(it.f, view(it.iter, index...))
@propagate_inbounds view(it::Filter, index...) = view(it.itr, index...)
@propagate_inbounds getindex(it::Generator, index...) = it.f(it.iter[index...])
