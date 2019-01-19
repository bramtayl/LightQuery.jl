downsize(::HasShape) = HasLength()
downsize(it) = it

struct Couples{It} it::It end
IteratorSize(c::Couples) = downsize(IteratorSize(c.it))
length(c::Couples) = length(c.it) - 1
IteratorEltype(c::Couples) = IteratorEltype(c.it)
eltype(c::Couples) = Tuple{eltype(c.it), eltype(c.it)}
iterate(c::Couples) = iterate(c, @ifsomething iterate(c.it))
function iterate(c::Couples, (last_item, state))
	item, state = @ifsomething iterate(c.it, state)
	(last_item, item), (item, state)
end

struct Cap{It, C}
	it::It
	cap::C
end
substitute_cap(c::Cap, result) =
	if result == nothing
		c.cap, nothing
	else
		result
	end
iterate(c::Cap) = substitute_cap(c, iterate(c.it))
iterate(c::Cap, state) = substitute_cap(c, iterate(c.it, state))
iterate(::Cap, ::Nothing) = nothing
IteratorSize(c::Cap) = downsize(IteratorSize(c.it))
IteratorEltype(c::Cap) = IteratorEltype(c.it)
length(c::Cap) = length(c.it) + 1
eltype(c::Cap{It, C}) where {It, C} = Union{eltype(c.it), C}

struct SkipRepeats{It} it::It end
IteratorSize(s::SkipRepeats) = SizeUnknown()
IteratorEltype(s::SkipRepeats) = HasEltype()
eltype(s::SkipRepeats) = eltype(s.it)
function iterate(s::SkipRepeats)
	(item, state) = @ifsomething iterate(s.it)
	item, (item, state)
end
function iterate(s::SkipRepeats, (last_item, state))
	item, next_state = @ifsomething iterate(s.it, state)
	if last_item == item
		iterate(s, (last_item, next_state))
	else
		item, (item, next_state)
	end
end

previous_index(it) = first(LinearEnumerate(it))
previous_index(it::Array, state::Int) = state - 1
previous_index(s::SkipRepeats, t::Tuple{T1, T2}) where {T1, T2} =
	previous_index(s.it, t[2])
previous_index(s::SkipRepeats) = previous_index(s.it)
previous_index(g::Generator, state) = previous_index(g.iter, state)
previous_index(g::Generator) = previous_index(g.iter)

struct Enumerate{It} it::It end
IteratorSize(e::Enumerate) = IteratorSize(e.it)
length(e::Enumerate) = length(e.it)
size(e::Enumerate) = size(e.it)
IteratorEltype(e::Enumerate) = IteratorEltype(e.it)
eltype(e::Enumerate) = Tuple{eltype(e.it), Int}
function iterate(e::Enumerate, state)
	item, state = @ifsomething iterate(e.it, state)
	(item, previous_index(e.it, state)), state
end
function iterate(e::Enumerate)
	item, state = @ifsomething iterate(e.it)
	(item, 1), state
end

export chunk_by
"""
	chunk_by(f, x)

Group `x` by consecutive results of `f`.

```jldoctest
julia> using LightQuery

julia> chunk_by(iseven, [1, 3, 2, 4]) |> collect
2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:
 false => [1, 3]
  true => [2, 4]
```
"""
chunk_by(f, x) = chunk_by(f, x, IteratorSize(x))
chunk_by(f, x, ::SizeUnknown) = chunk_by(f, collect(x), HasLength())
function chunk_by(f, x, ::Union{HasLength, HasShape})
	Generator(
		let x = x
			item_index__next_item_next_index -> begin
				((item, index), (next_item, next_index)) = item_index__next_item_next_index
				item => view(x, index:next_index - 1)
			end
		end,
		Couples(Cap(Enumerate(SkipRepeats(Generator(f, x))), (nothing, length(x) + 1)))
	)
end

export Matches
"""
	Matches(f, left, right)

Find where `f(left) == `f(right)`, assuming both are strictly sorted by f.

```jldoctest
julia> using LightQuery

julia> Matches(identity, [1, 2, 5], [1, 4, 5]) |> collect
2-element Array{Tuple{Int64,Int64},1}:
 (1, 1)
 (5, 5)
```
"""
struct Matches{F, Left, Right}
	f::F
	left::Left
	right::Right
end
IteratorEltype(m::Matches) = combine_iterator_eltype(
	IteratorEltype(m.left),
	IteratorEltype(m.left)
)
eltype(m::Matches) = Tuple{eltype(m.left), eltype(m.right)}

combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()

IteratorSize(m::Matches) = SizeUnknown()
iterate(m::Matches) = next_match(m,
	@ifsomething(iterate(m.left)),
	@ifsomething(iterate(m.right))
)
iterate(m::Matches, (left_state, right_state)) = next_match(m,
	@ifsomething(iterate(m.left, left_state)),
	@ifsomething(iterate(m.right, right_state))
)
function next_match(m, (left_item, left_state), (right_item, right_state))
	left_result = m.f(left_item)
	right_result = m.f(right_item)
	while left_result != right_result
		if isless(left_result, right_result)
			left_item, left_state = @ifsomething iterate(m.left, left_state)
			left_result = m.f(left_item)
		else
			right_item, right_state = @ifsomething iterate(m.right, right_state)
			right_result = m.f(right_item)
		end
	end
	(left_item, right_item), (left_state, right_state)
end
