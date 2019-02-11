"""
    By(it, call)

Marks that `it` has been pre-sorted by the key `call`. For use with
[`Group`](@ref) or [`FullJoin`](@ref).
"""
struct By{It, Call}
    it::It
    call::Call
end
export By

"""
    order(it, call; keywords...)
    order(it, call, condition; keywords...)

Generalized sort. `keywords` will be passed to `sort!`; see the documentation
there for options. See [`By`](@ref) for a way to explicitly mark that an object
has been sorted. Most performant if `call` is type stable, if not, consider
using a `condition` to filter.

```jldoctest
julia> using LightQuery

julia> order([2, 1], identity)
2-element view(::Array{Int64,1}, [2, 1]) with eltype Int64:
 1
 2

julia> order([1, 2, missing], identity, !ismissing)
2-element view(::Array{Union{Missing, Int64},1}, [1, 2]) with eltype Union{Missing, Int64}:
 1
 2
```
"""
order(it, call; keywords...) =
    @> Generator(call, it) |>
    enumerate |>
    collect |>
    sort!(_, by = last; keywords...) |>
    mappedarray(first, _) |>
    view(it, _)
order(it, call, condition; keywords...) =
    @> Generator(call, it) |>
    enumerate |>
    Filter(pair -> condition(pair[2]), _) |>
    collect |>
    sort!(_, by = last; keywords...) |>
    mappedarray(first, _) |>
    view(it, _)
export order

state_to_index(it::AbstractArray, state) = state[2] + 1
state_to_index(it::Array, state::Int) = state
state_to_index(it::Generator, state) = state_to_index(it.iter, state)
struct Group{It, Call}
    it::It
    call::Call
end
"""
    Group(it::By)

Group consecutive keys in `it`. Requires a presorted object (see [`By`](@ref)).
Relies on the fact that iteration states can be converted to indices; thus,
you might have to define `LightQuery.state_to_index` for unrecognized types.

```jldoctest
julia> using LightQuery

julia> Group(By([1, 3, 2, 4], iseven)) |> collect
2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:
 0 => [1, 3]
 1 => [2, 4]
```
"""
Group(it::By) = Group(it.it, it.call)
IteratorSize(::Type{It}) where It <: Group = SizeUnknown()
IteratorEltype(::Type{It}) where It <: Group = EltypeUnknown()
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
    right_index = state_to_index(it.it, state) - 1
    last_result => (@inbounds view(it.it, left_index:right_index - 1)), (state, right_index, result)
    end
end
function iterate(it::Group)
    item, state = @ifsomething iterate(it.it)
    iterate(it, (state, state_to_index(it.it, state) - 1, it.call(item)))
end
export Group

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
    FullJoin(left::By, right::By)

Find all pairs where `isequal(left.call(left.it), right.call(right.it))`.
Assumes `left` and `right` are both strictly sorted (no repeats). If there are
repeats, [`Group`](@ref) first. For other join flavors, combine with `Filter`.

```jldoctest
julia> using LightQuery

julia> FullJoin(
            By([1, 2, 5, 6], identity),
            By([1, 3, 4, 6], identity)
        ) |>
        collect
6-element Array{Pair{Union{Missing, Int64},Union{Missing, Int64}},1}:
       1 => 1
       2 => missing
 missing => 3
 missing => 4
       5 => missing
       6 => 6

julia> @> [1, 1, 2, 2] |>
        Group(By(_, identity)) |>
        By(_, first) |>
        FullJoin(_, By([1, 2], identity)) |>
        collect
2-element Array{Pair{Pair{Int64,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},Int64},1}:
 (1=>[1, 1]) => 1
 (2=>[2, 2]) => 2

julia> @> FullJoin(
            By([1, 2, 5, 6], identity),
            By([1, 3, 4, 6], identity)
        ) |>
        Filter((@_ !ismissing(_.first)), _) |>
        collect
4-element Array{Pair{Union{Missing, Int64},Union{Missing, Int64}},1}:
 1 => 1
 2 => missing
 5 => missing
 6 => 6
```
"""
struct FullJoin{Left <: By, Right <: By}
    left::Left
    right::Right
end
combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()
IteratorEltype(::Type{FullJoin{By{It1, Call1}, By{It2, Call2}}}) where {It1, Call1, It2, Call2} =
    combine_iterator_eltype(IteratorEltype(It1), IteratorEltype(It2))
eltype(::Type{FullJoin{By{It1, Call1}, By{It2, Call2}}}) where {It1, Call1, It2, Call2} =
    Pair{Union{Missing, eltype(It1)}, Union{Missing, eltype(It2)}}
IteratorSize(::Type{F}) where {F <: FullJoin} = SizeUnknown()
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
iterate(it::FullJoin, ::Nothing) = nothing
function iterate(it::FullJoin)
    left_history = next_history(it.left)
    right_history = next_history(it.right)
    full_dispatch(it, left_history, right_history)
end
function iterate(it::FullJoin, (left_history, right_history, next_left, next_right))
    if next_left
    left_history = next_history(it.left, left_history)
    end
    if next_right
    right_history = next_history(it.right, right_history)
    end
    full_dispatch(it, left_history, right_history)
end
export FullJoin

"""
    Length(it, length)

Allow optimizations based on length. Especially useful before
[`make_columns`](@ref).

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
IteratorEltype(::Type{Length{It}}) where It = IteratorEltype(It)
eltype(it::Length) = eltype(it.it)
IteratorLength(::Type{T}) where T <: Length = HasLength()
length(it::Length) = it.length
iterate(it::Length) = iterate(it.it)
iterate(it::Length, state) = iterate(it.it, state)
export Length

# piracy
@propagate_inbounds view(it::Generator, index...) = Generator(it.f, view(it.iter, index...))
