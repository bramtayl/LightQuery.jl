const Some{AType} = Tuple{AType, Vararg{AType}}

flatten_unrolled() = ()
flatten_unrolled(item, rest...) = item..., flatten_unrolled(rest...)...

reduce_unrolled(call, item) = item
reduce_unrolled(call, item1, item2, rest...) =
    reduce_unrolled(call, call(item1, item2), rest...)

map_unrolled(call, variables::Tuple{}) = ()
map_unrolled(call, variables) =
    call(first(variables)), map_unrolled(call, tail(variables))...

map_unrolled(call, variables1::Tuple{}, variables2::Tuple{}) = ()
map_unrolled(call, variables1, variables2) =
    call(first(variables1), first(variables2)),
    map_unrolled(call, tail(variables1), tail(variables2))...

partial_map(call, fixed, variables::Tuple{}) = ()
partial_map(call, fixed, variables) =
    call(fixed, first(variables)), partial_map(call, fixed, tail(variables))...

partial_map(call, fixed, variables1::Tuple{}, variables2::Tuple{}) = ()
partial_map(call, fixed, variables1, variables2) =
    call(fixed, first(variables1), first(variables2)),
    partial_map(call, fixed, tail(variables1), tail(variables2))...

filter_unrolled(call) = ()
filter_unrolled(call, item, rest...) =
    if call(item)
        item, filter_unrolled(call, rest...)...
    else
        rest
    end

if_not_in(::Tuple{}, it) = (it,)
if_not_in(them, it) =
    if first(them) === it
        ()
    else
        if_not_in(tail(them), it)
    end

diff_unrolled(more, less) =
    flatten_unrolled(partial_map(if_not_in, less, more)...)

"""
    over(iterator, call)

Lazy `map` with the reverse argument order.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred collect(over([1, -2, -3, 4], abs))
4-element Array{Int64,1}:
 1
 2
 3
 4
```
"""
over(iterator, call) = Generator(call, iterator)
export over

"""
    when(iterator, call)

Lazy `filter` with the reverse argument order.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred collect(when(1:4, iseven))
2-element Array{Int64,1}:
 2
 4
```
"""
when(iterator, call) = Filter(call, iterator)
export when

"""
    key(pair)

The `key` in a `key => value` `pair`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred key(:a => 1)
:a

julia> @inferred key((:a, 1))
:a
```
"""
function key(pair)
    a_key, a_value = pair
    a_key
end
key(pair::Pair) = pair.first
export key

"""
    value(pair)

The `value` in a `key => value` `pair`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred value(:a => 1)
1

julia> @inferred value((:a, 1))
1
```
"""
function value(pair)
    a_key, a_value = pair
    a_value
end
value(pair::Pair) = pair.second
export value

"""
    if_known(something)

If `something` is `missing`, return `missing`, otherwise, `something`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> function test(x)
            first(@if_known(x))
        end;

julia> @inferred test((1, 2))
1

julia> @inferred test(missing)
missing
```
"""
macro if_known(something)
    quote
        something = $(esc(something))
        if something === missing
            return missing
        else
            something
        end
    end
end
export @if_known

"""
    if_else(switch, yes, no)

`ifelse` that you can add methods to.

```jldoctest
julia> using LightQuery

julia> if_else(true, 1, 0)
1

julia> if_else(false, 1, 0)
0
```
"""
if_else(switch, yes, no) = ifelse(switch, yes, no)
export if_else
