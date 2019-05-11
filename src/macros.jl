struct CallCode{Call}
    call::Call
    code::Expr
end
(call_code::CallCode)(arguments...; keyword_arguments...) =
    call_code.call(arguments...; keyword_arguments...)

substitute_underscores!(dictionary, other) = other
substitute_underscores!(dictionary, maybe_argument::Symbol) =
    if all(isequal('_'), string(maybe_argument))
        if !haskey(dictionary, maybe_argument)
            dictionary[maybe_argument] = gensym(maybe_argument)
        end
        dictionary[maybe_argument]
    else
        maybe_argument
    end

function substitute_underscores!(dictionary, code::Expr)
    # have to do this the old fashioned way, _ has a special meaning in MacroTools
    if code.head === :macrocall && length(code.args) === 3
        name, location, body = code.args
        if name === Symbol("@_")
            code = anonymous(location, body)
        elseif name === Symbol("@>")
            code = make_chain(location, body)
        end
    end
    Expr(code.head, map(
        line -> substitute_underscores!(dictionary, line),
        code.args
    )...)
end

anonymous(location, other) = other
function anonymous(location, body::Expr)
    dictionary = Dict{Symbol, Symbol}()
    new_body = substitute_underscores!(dictionary, body)
    code = Expr(:function,
        Expr(:call, gensym(), Generator(
            pair -> value(pair),
            sort!(collect(dictionary), by = first)
        )...),
        Expr(:block, location, new_body)
    )
    Expr(:call,
        CallCode,
        code,
        quot(code)
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
    dictionary = Dict{Symbol, Symbol}()
    body = substitute_underscores!(dictionary, call)
    Expr(:let,
        Expr(:(=), dictionary[:_], object),
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

```jldoctest
julia> using LightQuery

julia> @> 0 |> _ - 1 |> abs
1
```
"""
macro >(body)
    make_chain(__source__, body) |> esc
end
export @>
