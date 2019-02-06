export By
"""
	By(it, call)

Marks that `it` has been pre-sorted by the key `call`. For use with
[`Group`](@ref) or [`LeftJoin`](@ref).
"""
struct By{It, Call}
    it::It
	call::Call
end

export order
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
	view(it, mappedarray(
		first,
		sort!(collect(enumerate(Generator(call, it))), by = last; keywords...)
	))
order(it, call, condition; keywords...) =
	view(it, mappedarray(
		first,
		sort!(collect(when(
			enumerate(Generator(call, it)),
			pair -> condition(pair[2])
		)), by = last; keywords...)
	))

state_to_index(it::AbstractArray, state) = state[2] + 1
state_to_index(it::Array, state::Int) = state
state_to_index(it::Generator, state) = state_to_index(it.iter, state)

export Group
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
 false => [1, 3]
  true => [2, 4]
```
"""
@inline Group(it::By) = Group(it.it, it.call)

IteratorSize(::Type{It}) where It <: Group = SizeUnknown()
IteratorEltype(::Type{It}) where It <: Group  = EltypeUnknown()

function iterate(it::Group)
	item, state = @ifsomething iterate(it.it)
	iterate(it, (state, state_to_index(it.it, state) - 1, it.call(item)))
end
iterate(it::Group, ::Nothing) = nothing
function iterate(it::Group, (state, left_index, last_result))
	item_state = iterate(it.it, state)
	if item_state === nothing
		last_result => (@inbounds view(it.it, left_index:length(it.it))), nothing
	else
		item, state = item_state
		result = it.call(item)
		while isequal(result, last_result)
			# manual inlining of iterate to avoid stackoverflow detector
			item_state = iterate(it.it, state)
			if item_state === nothing
				return last_result => (@inbounds view(it.it, left_index:length(it.it))), nothing
			else
				item, state = item_state
				if state === nothing
					return nothing
				end
				result = it.call(item)
			end
		end
		right_index = state_to_index(it.it, state) - 1
		last_result => (@inbounds view(it.it, left_index:right_index - 1)), (state, right_index, result)
	end
end

struct History{State, Item, Result}
	state::State
	item::Item
	result::Result
end

History(it::By, ::Nothing) = nothing
History(it::By, (item, state)) = History(state, item, it.call(item))

next_history(it::By) = History(it, iterate(it.it))
next_history(it::By, history::History) = History(it, iterate(it.it, history.state))
isless(history1::History, history2::History) = isless(history1.result, history2.result)

export LeftJoin
"""
	LeftJoin(left::By, right::By)

For each value in `left`, look for a value with the same key in `right`.
Requires both to be presorted (see [`By`](@ref)).

```jldoctest
julia> using LightQuery

julia> LeftJoin(
            By([1, 2, 5, 6], identity),
            By([1, 3, 4, 6], identity)
       ) |> collect
4-element Array{Pair{Int64,Union{Missing, Int64}},1}:
 1 => 1
 2 => missing
 5 => missing
 6 => 6
```
"""
struct LeftJoin{Left <: By, Right <: By}
	left::Left
	right::Right
end

combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()
IteratorEltype(::Type{LeftJoin{By{It1, Call1}, By{It2, Call2}}}) where {It1, Call1, It2, Call2} =
	combine_iterator_eltype(IteratorEltype(It1), IteratorEltype(It2))
eltype(::Type{LeftJoin{By{It1, Call1}, By{It2, Call2}}}) where {It1, Call1, It2, Call2} =
	Pair{eltype(It1), Union{Missing, eltype(It2)}}

IteratorSize(::Type{LeftJoin{By{It1, Call1}, Right}}) where {It1, Call1, Right} =
	IteratorSize(It1)
length(it::LeftJoin) = length(it.left.it)
size(it::LeftJoin) = size(it.left.it)
function iterate(it::LeftJoin)
	left_match = @ifsomething next_history(it.left)
	seek_right_match(it, left_match, next_history(it.right))
end
iterate(it::LeftJoin, ::Nothing) = nothing
function iterate(it::LeftJoin, (left_history, right_history))
	left_history = @ifsomething next_history(it.left, left_history)
    seek_right_match(it, left_history, right_history)
end
seek_right_match(it, left_history, ::Nothing) =
	(left_history.item => missing), nothing
function seek_right_match(it, left_history, right_history)
	while isless(right_history, left_history)
		right_history = next_history(it.right, right_history)
        if right_history === nothing
            return (left_history.item => missing), nothing
        end
	end
	if isless(left_history, right_history)
		(left_history.item => missing), (left_history, right_history)
	else
		(left_history.item => right_history.item), (left_history, right_history)
	end
end

export over
"""
	over(it, call)

Lazy version of map, with the reverse argument order.

```jldoctest
julia> using LightQuery

julia> over([1, 2], x -> x + 0.0) |> collect
2-element Array{Float64,1}:
 1.0
 2.0
```
"""
over(it, call) = Generator(call, it)

export when
"""
	when(it, call)

Lazy version of filter, with the reverse argument order.

```jldoctest
julia> using LightQuery

julia> when([1, 2], x -> x > 1) |> collect
1-element Array{Int64,1}:
 2
```
"""
when(it, call) = Filter(call, it)

# piracy
@propagate_inbounds view(it::Generator, index...) = Generator(it.f, view(it.iter, index...))
@propagate_inbounds view(arrays::ZippedArrays, index...) = zip(map(
	array -> view(array, index...),
	arrays.arrays
)...)
