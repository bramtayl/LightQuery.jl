export Nameless

"A container for a function and the expression that generated it"
struct Nameless{F}
    f::F
    expression::Expr
end

(nameless::Nameless)(arguments...; keyword_arguments...) =
    nameless.f(arguments...; keyword_arguments...)

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

function unname_simple(body::Expr, line, file)
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


function unname(body::Expr, line, file)
    Expr(:call, Nameless, unname_simple(body, line, file), quot(body))
end

function unname(body, line, file)
    unname(Expr(:block, LineNumberNode(line, file), body), line, file)
end

export @_
"""
    macro _(body::Expr)

Create an `Nameless` object. The arguments are inside the body; the
first arguments is `_`, the second argument is `__`, etc. Also stores a
quoted version of the function.

```jldoctest
julia> using LightQuery

julia> 1 |> @_(_ + 1)
2

julia> map(@_(__ - _), (1, 2), (2, 1))
(1, -1)

julia> @_(_ + 1).expression
:(_ + 1)
```
"""
macro _(body)
    unname(macroexpand(@__MODULE__, body), @__LINE__, @__FILE__) |> esc
end

chain(body, line, file) =
    if @capture body head_ |> tail_
        Expr(:call, unname_simple(tail, line, file), chain(head, line, file))
    else
        body
    end

export @>
"""
    macro >(body)

If body is in the form `body_ |> tail_`, call `@_` on `tail`, and recur on `body`.

```jldoctest
julia> using LightQuery

julia> @> 0 |> _ + 1 |> _ - 1
0
```
"""
macro >(body)
    chain(macroexpand(@__MODULE__, body), @__LINE__, @__FILE__) |> esc
end
