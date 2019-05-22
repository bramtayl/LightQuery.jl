substitute_underscores!(underscores_to_gensyms, other) = other
substitute_underscores!(underscores_to_gensyms, maybe_argument::Symbol) =
    if all(isequal('_'), string(maybe_argument))
        if !haskey(underscores_to_gensyms, maybe_argument)
            underscores_to_gensyms[maybe_argument] = gensym(maybe_argument)
        end
        underscores_to_gensyms[maybe_argument]
    else
        maybe_argument
    end
function substitute_underscores!(underscores_to_gensyms, code::Expr)
    # have to do this the old fashioned way because _ has a special meaning in MacroTools
    expanded_code =
        if code.head === :macrocall && length(code.args) === 3
            name, location, body = code.args
            if name === Symbol("@_")
                anonymous(location, body)
            elseif name === Symbol("@>")
                make_chain(location, body)
            end
        else
            code
        end
    Expr(expanded_code.head, map(
        arg -> substitute_underscores!(underscores_to_gensyms, arg),
        expanded_code.args
    )...)
end

anonymous(location, other) = other
function anonymous(location, body::Expr)
    underscores_to_gensyms = Dict{Symbol, Symbol}()
    substituted_body = substitute_underscores!(underscores_to_gensyms, body)
    Expr(:function,
        Expr(:call, gensym("@_"), over(
            sort!(collect(underscores_to_gensyms), by = first),
            value
        )...),
        Expr(:block, location, substituted_body)
    )
end

"""
    macro _(body)

Terser function syntax. The arguments are inside the `body`; the first argument is `_`, the second argument is `__`, etc.

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

function link(location, object, call::Expr)
    underscores_to_gensyms = Dict{Symbol, Symbol}()
    body = substitute_underscores!(underscores_to_gensyms, call)
    Expr(:let,
        Expr(:(=), underscores_to_gensyms[:_], object),
        Expr(:block,
            location,
            body
        )
    )
end
link(location, object, call) = Expr(:call, call, object)

make_chain(location, maybe_chain) =
    if @capture maybe_chain object_ |> call_
        link(location, make_chain(location, object), call)
    else
        maybe_chain
    end

"""
    macro >(body)

If body is in the form `object_ |> call_`, call [`@_`](@ref) on `call`, and recur on `object`.

```jldoctest chain
julia> using LightQuery

julia> @> 0 |> _ - 1 |> abs
1
```

You can nest chains:

```jldoctest chain
julia> @> 1 |> (@> _ + 1 |> _ + 1)
3
```
"""
macro >(body)
    make_chain(__source__, body) |> esc
end
export @>
