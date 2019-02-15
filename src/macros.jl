function substitute_underscores!(dictionary, body)
    body
end
function substitute_underscores!(dictionary, body::Symbol)
    if all(isequal('_'), string(body))
        if !haskey(dictionary, body)
            dictionary[body] = gensym("`_`")
        end
        dictionary[body]
    else
        body
    end
end
function substitute_underscores!(dictionary, body::Expr)
    Expr(body.head, map(
        let dictionary = dictionary
            body -> substitute_underscores!(dictionary, body)
        end,
        body.args
    )...)
end
anonymous(location, body) = body
function anonymous(location, body::Expr)
    dictionary = Dict{Symbol, Symbol}()
    new_body = substitute_underscores!(dictionary, body)
    arguments = Generator(
        pair -> pair.second,
        sort(collect(dictionary))
    )
    function_name = gensym(string('`', body, '`'))
    Expr(:function,
        Expr(:call, function_name, arguments...),
        Expr(:block,
            Expr(:meta, :inline),
            location,
            new_body
        )
    )
end

"""
    macro _(body)

Terser function syntax. The arguments are inside the body; the first
argument is `_`, the second argument is `__`, etc.

```jldoctest
julia> using LightQuery

julia> (@_ _ + 1)(1)
2

julia> map((@_ __ - _), (1, 2), (2, 1))
(1, -1)
```
"""
macro _(body)
    anonymous(LineNumberNode(@__LINE__, @__FILE__), macroexpand(@__MODULE__, body)) |> esc
end
export @_

function chain(location, body)
    if @capture body head_ |> tail_
        Expr(:call, anonymous(location, tail), chain(location, head))
    else
        body
    end
end
"""
    macro >(body)

If body is in the form `body_ |> tail_`, call [`@_`](@ref) on `tail`, and recur on `body`.

```jldoctest
julia> using LightQuery

julia> @> 0 |> _ - 1 |> abs
1
```
"""
macro >(body)
    chain(LineNumberNode(@__LINE__, @__FILE__), macroexpand(@__MODULE__, body)) |> esc
end
export @>
