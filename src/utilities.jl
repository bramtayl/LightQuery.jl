const Some{AType} = Tuple{AType, Vararg{AType}}

@inline function flatten_unrolled()
    ()
end
@inline function flatten_unrolled(item, rest...)
    item..., flatten_unrolled(rest...)...
end

@inline function reduce_unrolled(call, item)
    item
end
@inline function reduce_unrolled(call, item1, item2, rest...)
    reduce_unrolled(call, call(item1, item2), rest...)
end

@inline function map_unrolled(call, variables::Tuple{})
    ()
end
@inline function map_unrolled(call, variables)
    call(first(variables)), map_unrolled(call, tail(variables))...
end

@inline function map_unrolled(call, variables1::Tuple{}, variables2::Tuple{})
    ()
end
@inline function map_unrolled(call, variables1, variables2)
    call(first(variables1), first(variables2)),
    map_unrolled(call, tail(variables1), tail(variables2))...
end

@inline function partial_map(call, fixed, variables::Tuple{})
    ()
end
@inline function partial_map(call, fixed, variables)
    call(fixed, first(variables)), partial_map(call, fixed, tail(variables))...
end

@inline function partial_map(call, fixed, variables1::Tuple{}, variables2::Tuple{})
    ()
end
@inline function partial_map(call, fixed, variables1, variables2)
    call(fixed, first(variables1), first(variables2)),
    partial_map(call, fixed, tail(variables1), tail(variables2))...
end


@inline function filter_unrolled(call)
    ()
end
@inline function filter_unrolled(call, item, rest...)
    if call(item)
        item, filter_unrolled(call, rest...)...
    else
        rest
    end
end

@inline in_unrolled(needle) = false
@inline in_unrolled(needle, hay, stack...) =
    if needle === hay
        true
    else
        in_unrolled(needle, stack...)
    end
@inline diff_unrolled(less) = ()
@inline diff_unrolled(less, first_more, mores...) =
    if in_unrolled(first_more, less...)
        diff_unrolled(less, mores...)
    else
        first_more, diff_unrolled(less, mores...)...
    end

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
@inline function over(iterator, call)
    Generator(call, iterator)
end
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
@inline function when(iterator, call)
    Iterators.filter(call, iterator)
end
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
@inline function key((a_key, a_value))
    a_key
end
@inline function key(pair::Pair)
    pair.first
end
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
@inline function value((a_key, a_value))
    a_value
end
@inline function value(pair::Pair)
    pair.second
end
export value

"""
    @if_known(something)

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
