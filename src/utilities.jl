const Some{AType} = Tuple{AType, Vararg{AType}}

flatten_unrolled(::Tuple{}) = ()
flatten_unrolled(them::Some{Any}) =
    first(them)..., flatten_unrolled(tail(them))...

@inline partial_map(f, fixed, variables::Vararg{Tuple{}}) = ()
@inline partial_map(f, fixed, variables::Vararg{Tuple}) =
    f(fixed, map(first, variables)...),
    partial_map(f, fixed, map(tail, variables)...)...
@inline partial_map(f, fixed, variables) = map(
    let fixed = fixed
        variable -> f(fixed, variable)
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

function val_fieldtypes_or_empty(type::TypeofBottom)
    @warn "Unable to infer the fieldtypes of $type, defaulting to `()` for empty iterators. Likely to due inner function error"
    ()
end
function val_fieldtypes_or_empty(type::Union)
    @warn "Unable to infer the fieldtypes of the Union type $type, defaulting to `()` for empty iterators"
    ()
end
function val_fieldtypes_or_empty(type::UnionAll)
    @warn "Unable to infer the fieldtypes of the UnionAll type $type, defaulting to `()` for empty iterators"
    ()
end
@pure val_fieldtypes_or_empty(type::DataType) =
    if type.abstract
        @warn "Unable to infer the fieldtypes of the abstract type $type, defaulting to `()` for empty iterators"
        ()
    elseif (type.name === Tuple.name && isvatuple(type))
        @warn "Unable to infer the fieldtypes of the Varargs type $type, defaulting to `()` for empty iterators"
        ()
    else
        map(Val, fieldtypes(type))
    end

"""
    over(iterator, call)

Lazy `map` with the reverse argument order.
"""
over(iterator, call) = Generator(call, iterator)
export over

"""
    when(iterator, call)

Lazy `filter` with the reverse argument order.
"""
when(iterator, call) = Filter(call, iterator)
export when

"""
    key(pair)

The `key` in a `key => value` `pair`.
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
