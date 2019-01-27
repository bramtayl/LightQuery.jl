substitute_underscores!(dictionary, body) = body
substitute_underscores!(dictionary, body::Symbol) =
    if all(isequal('_'), string(body))
        if !haskey(dictionary, body)
            dictionary[body] = gensym("argument")
        end
        dictionary[body]
    else
        body
    end
substitute_underscores!(dictionary, body::Expr) =
    if body.head == :quote
        body
    else
        Expr(body.head,
            map(body -> substitute_underscores!(dictionary, body), body.args)
        ...)
    end

string_length(something) = something |> String |> length

unname(body, line, file) = unname(:($body(_)), line, file)

function unname(body::Expr, line, file)
    dictionary = Dict{Symbol, Symbol}()
    new_body = substitute_underscores!(dictionary, body)
    sorted_dictionary = sort(
        lt = (pair1, pair2) ->
            isless(string_length(pair1.first), string_length(pair2.first)),
        collect(dictionary)
    )
    Expr(:->,
        Expr(:tuple, (pair.second for pair in sorted_dictionary)...),
        Expr(:block, LineNumberNode(line, file), new_body)
    )
end

export @_
"""
    macro _(body)

Terser function syntax. The arguments are inside the body; the first
argument is `_`, the second argument is `__`, etc.

```jldoctest
julia> using LightQuery

julia> 1 |> @_(_ + 1)
2

julia> map(@_(__ - _), (1, 2), (2, 1))
(1, -1)
```
"""
macro _(body)
    unname(macroexpand(@__MODULE__, body), @__LINE__, @__FILE__) |> esc
end

chain(body, line, file) =
    if @capture body head_ |> tail_
        Expr(:call, unname(tail, line, file), chain(head, line, file))
    else
        body
    end

export @>
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
    chain(macroexpand(@__MODULE__, body), @__LINE__, @__FILE__) |> esc
end
