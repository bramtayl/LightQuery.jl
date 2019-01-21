macro ifsomething(ex, alt)
    quote
        result = $(esc(ex))
        result === nothing && return $(esc(alt))
        result
    end
end

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
previous_index(z::Zip, t::Tuple) = previous_index(z.is[1], t[1])

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

struct By{F, It}
	f::F
	it::It
end
struct History{S, I, R}
	state::S
	item::I
	result::R
end

History(b::By, ::Nothing) = nothing
function History(b::By, item_state)
	item, state = item_state
	History(state, item, b.f(item))
end

iterate(b::By) = History(b, iterate(b.it))
iterate(b::By, h::History) = History(b, iterate(b.it, h.state))
isless(h1::History, h2::History) = isless(h1.result, h2.result)

export LeftJoin
"""
	LeftJoin(left_key, right_key, left, right)
	LeftJoin(left_key, [right_key = left_key], left, right)

Return each value in `left`, and, if it exists, the item in `right` where
`isequal(left_key(left), right_key(right))`, assuming both are strictly sorted
by the respective keys.

```jldoctest
julia> using LightQuery

julia> LeftJoin(identity, [1, 2, 5, 6], [1, 3, 4, 6]) |> collect
4-element Array{Tuple{Int64,Union{Missing, Int64}},1}:
 (1, 1)
 (2, missing)
 (5, missing)
 (6, 6)
```
"""
struct LeftJoin{Left <: By, Right <: By}
	left::Left
	right::Right
end
LeftJoin(left_key, right_key, left, right) = LeftJoin(By(left_key, left), By(right_key, right))
LeftJoin(left_key, left, right) = LeftJoin(left_key, left_key, left, right)
combine_iterator_eltype(::HasEltype, ::HasEltype) = HasEltype()
combine_iterator_eltype(x, y) = EltypeUnknown()
IteratorEltype(m::LeftJoin) = combine_iterator_eltype(
	IteratorEltype(m.left.it),
	IteratorEltype(m.right.it)
)
eltype(m::LeftJoin) = Tuple{
    eltype(m.left.it),
    Union{Missing, eltype(m.right.it)}
}
IteratorSize(m::LeftJoin) = IteratorSize(m.left.it)
length(m::LeftJoin) = length(m.left.it)
size(m::LeftJoin) = size(m.left.it)
function iterate(m::LeftJoin)
	left_history = iterate(m.left)
    if left_history === nothing
        nothing
    else
	    right_history = iterate(m.right)
        if right_history === nothing
            (left_history.item, missing), nothing
        else
            seek_right_match(m, left_history, right_history)
        end
    end
end
iterate(m::LeftJoin, ::Nothing) = nothing
function iterate(m::LeftJoin, (left_history, right_history))
	left_history = iterate(m.left, left_history)
    if left_history === nothing
        nothing
    else
        seek_right_match(m, left_history, right_history)
    end
end
function seek_right_match(m, left_history, right_history)
	while isless(right_history, left_history)
		right_history = iterate(m.right, right_history)
        if right_history === nothing
            return (left_history.item, missing), nothing
        end
	end
	if isless(left_history, right_history)
		# no way we can find any more matches to left item
		(left_history.item, missing), (left_history, right_history)
	else
        # they are equal
		(left_history.item, right_history.item), (left_history, right_history)
	end
end

# piracy
view(g::Generator, args...) = Generator(g.f, view(g.iter, args...))
view(z::Zip, args...) = zip(map(
	i -> view(i, args...),
	z.is
)...)
IteratorSize(g::Generator) = IteratorSize(g.iter)
