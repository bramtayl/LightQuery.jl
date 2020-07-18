const SomeOf{AType} = NTuple{N,AType} where {N}

@inline function flatten_unrolled()
    ()
end
@inline function flatten_unrolled(container, rest...)
    container..., flatten_unrolled(rest...)...
end

@inline function my_flatten(containers)
    # TODO: avoid recursion for large tuples
    flatten_unrolled(containers...)
end

@inline function all_unrolled()
    true
end
@inline function all_unrolled(item1, rest...)
    if item1
        all_unrolled(rest...)
    else
        false
    end
end

@inline function my_all(items)
    # TODO: avoid recursion for large tuples
    all_unrolled(items...)
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
@inline function map_unrolled(call, variables1, ::Tuple{})
    error("Mismatch in map: $variables1 left over")
end
@inline function map_unrolled(call, ::Tuple{}, variables2)
    error("Mismatch in map: $variables2 left over")
end

@inline function my_map(call, variables)
    # TODO: avoid recursion for large tuples
    map_unrolled(call, variables)
end
@inline function my_map(call, variables1, variables2)
    # TODO: avoid recursion for large tuples
    map_unrolled(call, variables1, variables2)
end

@inline function partial_map_unrolled(call, fixed, variables::Tuple{})
    ()
end
@inline function partial_map_unrolled(call, fixed, variables)
    call(fixed, first(variables)), partial_map_unrolled(call, fixed, tail(variables))...
end
@inline function partial_map_unrolled(call, fixed, variables1::Tuple{}, variables2::Tuple{})
    ()
end
@inline function partial_map_unrolled(call, fixed, variables1, variables2)
    call(fixed, first(variables1), first(variables2)),
    partial_map_unrolled(call, fixed, tail(variables1), tail(variables2))...
end
@inline function partial_map_unrolled(call, fixed, variables1, ::Tuple{})
    error("Mismatch in partial map: $variables1 left over")
end
@inline function partial_map_unrolled(call, fixed, ::Tuple{}, variables2)
    error("Mismatch in partial map: $variables2 left over")
end

@inline function partial_map(call, fixed, variables)
    # TODO: avoid recursion for large tuples
    partial_map_unrolled(call, fixed, variables)
end
@inline function partial_map(call, fixed, variables1, variables2)
    # TODO: avoid recursion for large tuples
    partial_map_unrolled(call, fixed, variables1, variables2)
end

@inline in_unrolled(needle) = false
@inline in_unrolled(needle, hay, stack...) =
    if needle === hay
        true
    else
        in_unrolled(needle, stack...)
    end

@inline setdiff_unrolled(less) = ()
@inline function setdiff_unrolled(less, first_more, mores...)
    rest = setdiff_unrolled(less, mores...)
    if in_unrolled(first_more, less...)
        rest
    else
        first_more, rest...
    end
end

@inline function my_setdiff(more, less)
    # TODO: avoid recursion for large tuples
    setdiff_unrolled(less, more...)
end

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
