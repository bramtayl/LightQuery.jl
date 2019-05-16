const Some{AType} = Tuple{AType, Vararg{AType}}

val_fieldtypes_or_empty(something) = ()
@pure val_fieldtypes_or_empty(type::DataType) =
    if type.abstract || (type.name === Tuple.name && isvatuple(type))
        ()
    else
        map(Val, fieldtypes(type))
    end

flatten_unrolled(::Tuple{}) = ()
flatten_unrolled(them::Some{Any}) =
    first(them)..., flatten_unrolled(tail(them))...

reduce_unrolled(f, x, y, z...) = reduce_unrolled(f, f(x, y), z...)
reduce_unrolled(f, x) = x

@inline partial_map(f, fixed, variables::Vararg{Tuple{}}) = ()
@inline partial_map(f, fixed, variables::Vararg{Tuple}) =
    f(fixed, map(first, variables)...),
    partial_map(f, fixed, map(tail, variables)...)...
@inline partial_map(f, fixed, variables) = map(
    let f = f, fixed = fixed
        partial_map_at(variable) = f(fixed, variable)
    end,
    variables
)

filter_unrolled(f, ::Tuple{}) = ()
function filter_unrolled(f, them::Some{Any})
    head = first(them)
    rest = filter_unrolled(f, tail(them))
    if f(head)
        head, rest...
    else
        rest
    end
end

"""
    over(iterator, call)

Lazy `map` with the reverse argument order.

```jldoctest
julia> using LightQuery

julia> collect(over([1, -2, -3, 4], abs))
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

julia> collect(when(1:4, iseven))
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

julia> key(:a => 1)
:a

julia> key((:a, 1))
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

julia> value(:a => 1)
1

julia> value((:a, 1))
1
```
"""
function value(pair::Tuple{Any, Any})
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

julia> function test(x)
            first(@if_known(x))
        end;

julia> test((1, 2))
1

julia> test(missing)
missing
```
"""
macro if_known(something)
    quote
        let something = $(esc(something))
            if something === missing
                return missing
            else
                something
            end
        end
    end
end
export @if_known
