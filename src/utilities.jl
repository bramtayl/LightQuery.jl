const SomeOf{AType} = NTuple{N,AType} where {N}

@inline function flatten_unrolled()
    ()
end
@inline function flatten_unrolled(container, rest...)
    container..., flatten_unrolled(rest...)...
end

function my_flatten(containers)
    if length(containers) > LONG
        (flatten(containers)...,)
    else
        flatten_unrolled(containers...)
    end
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

function my_all(items)
    if length(items) > LONG
        all(items)
    else
        all_unrolled(items...)
    end
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

function inner_map_1(call, fixed)
    function (variable)
        call(fixed, variable)
    end
end
function inner_map_2(call, fixed)
    function (variable1, variable2)
        call(fixed, variable1, variable2)
    end
end

function partial_map(call, fixed, variables)
    if length(variables) > LONG
        map(inner_map_1(call, fixed), variables)
    else
        partial_map_unrolled(call, fixed, variables)
    end
end
function partial_map(call, fixed, variables1, variables2)
    if length(variables1) > LONG
        map(inner_map_2(call, fixed), variables1, variables2)
    else
        partial_map_unrolled(call, fixed, variables1, variables2)
    end
end
function partial_for_each(call, fixed, variables)
    if length(variables) > LONG
        foreach(inner_map_1(call, fixed), variables)
        nothing
    else
        partial_map_unrolled(call, fixed, variables)
        nothing
    end
end
function partial_for_each(call, fixed, variables1, variables2)
    if length(variables1) > LONG
        foreach(inner_map_2(call, fixed), variables1, variables2)
        nothing
    else
        partial_map_unrolled(call, fixed, variables1, variables2)
        nothing
    end
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

function my_setdiff(more, less)
    if length(more) > LONG
        (setdiff(more, less)...,)
    else
        setdiff_unrolled(less, more...)
    end
end

"""
    over(iterator, call)

Lazy `map` with the reverse argument order.

```jldoctest
julia> using LightQuery


julia> using Test: @inferred


julia> @inferred collect(over([1, -2, -3, 4], abs))
4-element Vector{Int64}:
 1
 2
 3
 4
```
"""
function over(iterator, call)
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
2-element Vector{Int64}:
 2
 4
```
"""
function when(iterator, call)
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
function key((a_key, a_value))
    a_key
end
function key(pair::Pair)
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
function value((a_key, a_value))
    a_value
end
function value(pair::Pair)
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
