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

previous_index(it::Array, state::Int) = state - 1
previous_index(s::SkipRepeats, t::Tuple{T1, T2}) where {T1, T2} =
	previous_index(s.it, t[2])
previous_index(g::Generator, state) = previous_index(g.iter, state)
previous_index(z::Zip, t::Tuple) = previous_index(z.is[1], t[1])
previous_index(s::StepRange, t::Tuple) = t[2]

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

export key
"""
    key(pair)

The first item
"""
key(p::Pair) = p.first

export value
"""
    value(pair)

The second item
"""
value(p::Pair) = p.second

export By
"""
	By(it, f)

Marks that `it` has been pre-sorted by the key `f`.
"""
struct By{It, F}
    it::It
	f::F
end

export group
"""
    group(b::By)

Group consecutive keys in `b`.

```jldoctest
julia> using LightQuery

julia> group(By([1, 3, 2, 4], iseven)) |> collect
2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:
 false => [1, 3]
  true => [2, 4]
```
"""
group(b::By) = group_inner(b.f, b.it, IteratorSize(b.it))

group_inner(f, x, ::SizeUnknown) = group(f, collect(x), HasLength())
function group_inner(f, x, ::Union{HasLength, HasShape})
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
	LeftJoin(left::By, right::By)

For each value in left, look for a value with the same key in right.

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
IteratorEltype(l::LeftJoin) = combine_iterator_eltype(
	IteratorEltype(l.left.it),
	IteratorEltype(l.right.it)
)
eltype(l::LeftJoin) = Pair{
    eltype(l.left.it),
    Union{Missing, eltype(l.right.it)}
}
IteratorSize(l::LeftJoin) = IteratorSize(l.left.it)
length(l::LeftJoin) = length(l.left.it)
size(l::LeftJoin) = size(l.left.it)
function iterate(l::LeftJoin)
	left_history = iterate(l.left)
    if left_history === nothing
        nothing
    else
	    right_history = iterate(l.right)
        if right_history === nothing
            (left_history.item => missing), nothing
        else
            seek_right_match(l, left_history, right_history)
        end
    end
end
iterate(l::LeftJoin, ::Nothing) = nothing
function iterate(l::LeftJoin, (left_history, right_history))
	left_history = iterate(l.left, left_history)
    if left_history === nothing
        nothing
    else
        seek_right_match(l, left_history, right_history)
    end
end
function seek_right_match(l, left_history, right_history)
	while isless(right_history, left_history)
		right_history = iterate(l.right, right_history)
        if right_history === nothing
            return (left_history.item => missing), nothing
        end
	end
	if isless(left_history, right_history)
		# no way we can find any more matches to left item
		(left_history.item => missing), (left_history, right_history)
	else
        # they are equal
		(left_history.item => right_history.item), (left_history, right_history)
	end
end

export over
over(x, f) = Generator(f, x)

export when
when(x, f) = Filter(f, x)

# piracy
view(g::Generator, args...) = Generator(g.f, view(g.iter, args...))
view(z::Zip, args...) = zip(map(
	i -> view(i, args...),
	z.is
)...)
IteratorSize(g::Generator) = IteratorSize(g.iter)
