second(it) = it[2]

const Some{AType} = Tuple{AType, Vararg{AType}}

flatten_unrolled(::Tuple{}) = ()
flatten_unrolled(them) =
    them[1]..., flatten_unrolled(tail(them))...

partial_map(f, fixed, variables::Tuple{}) = ()
partial_map(f, fixed, variables::Tuple) =
    f(fixed, variables[1]), partial_map(f, fixed, tail(variables))...
partial_map(f, fixed, ::Tuple{}, ::Tuple{}) = ()
partial_map(f, fixed, variables1::Tuple, variables2::Tuple) =
    f(fixed, variables1[1], variables2[1]),
    partial_map(f, fixed, tail(variables1), tail(variables2))...
partial_map(f, fixed, variables) = map(
    let fixed = fixed
        variable -> f(fixed, variable)
    end,
    variables
)
partial_map(f, fixed, variables1, variables2) = map(
    let fixed = fixed
        (variable1, variable2) -> f(fixed, variable1, variable2)
    end,
    variables1, variables2
)

@generated type_length(::Val{AType}) where {AType} = Val{fieldcount(AType)}()

"""
    over(iterator, call)

Lazy `map` with argument order reversed.
"""
over(iterator, call) = Generator(call, iterator)
export over

"""
    when(iterator, call)

Lazy `filter` with argument order reversed.
"""
when(iterator, call) = Filter(call, iterator)
export when

"""
    key(pair)

The `key` in a `key => value` `pair`.
"""
key(pair::Pair) = pair.first
export key

"""
    value(pair)

The `value` in a `key => value` `pair`.
"""
value(pair::Pair) = pair.second
export value
