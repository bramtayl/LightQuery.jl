substitute_underscores!(dictionary, body) = body
substitute_underscores!(dictionary, body::Symbol) =
    if all(isequal('_'), string(body))
        if !haskey(dictionary, body)
            dictionary[body] = gensym(body)
        end
        dictionary[body]
    else
        body
    end
function substitute_underscores!(dictionary, body::Expr)
    # have to do this the old fashioned way, _ has a special meaning in MacroTools
    if body.head === :macrocall && length(body.args) === 3
        name, location, inner_body = body.args
        if name === Symbol("@_")
            body = anonymous(location, inner_body)
        elseif name === Symbol("@>")
            body = chain(location, inner_body)
        end
    end
    Expr(body.head, map(
        body -> substitute_underscores!(dictionary, body),
        body.args
    )...)
end
anonymous(location, body) = body
function anonymous(location, body::Expr)
    dictionary = Dict{Symbol, Symbol}()
    new_body = substitute_underscores!(dictionary, body)
    Expr(:function,
        Expr(:call, Symbol(string("(@_ ", body, ")")), Generator(
            pair -> pair.second,
            sort!(collect(dictionary), by = first)
        )...),
        Expr(:block, Expr(:meta, :inline), location, new_body)
    )
end

"""
    macro _(body)

Terser function syntax. The arguments are inside the body; the first
argument is `_`, the second argument is `__`, etc. Will always `@inline`.

```jldoctest
julia> using LightQuery

julia> (@_ _ + 1)(1)
2

julia> map((@_ __ - _), (1, 2), (2, 1))
(1, -1)
```
"""
macro _(body)
    anonymous(__source__, body) |> esc
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

If body is in the form `body_ |> tail_`, call [`@_`](@ref) on `tail`, and recur
on `body`.

```jldoctest
julia> using LightQuery

julia> @> 0 |> _ - 1 |> abs
1
```
"""
macro >(body)
    chain(__source__, body) |> esc
end
export @>
