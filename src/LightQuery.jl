module LightQuery

import MacroTools: @capture
import Base: Generator
import Base.Iterators: flatten
import Base.Meta: quot

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
    elseif @capture body @_ args__
        body
    else
        Expr(body.head,
            map(body -> substitute_underscores!(dictionary, body), body.args)
        ...)
    end

string_length(something) = something |> String |> length

function anonymize(body, line, file)
    dictionary = Dict{Symbol, Symbol}()
    new_body = substitute_underscores!(dictionary, body)
    sorted_dictionary = sort(
        lt = (pair1, pair2) ->
            isless(string_length(pair1.first), string_length(pair2.first)),
        collect(dictionary)
    )
    Expr(:->,
        Expr(:tuple, Generator(pair -> pair.second, sorted_dictionary)...),
        Expr(:block, LineNumberNode(line, file), new_body)
    )
end

export @_
"""
    macro _(body::Expr)

Another syntax for anonymous functions. The arguments are inside the body; the
first arguments is `_`, the second argument is `__`, etc.

```jldoctest
julia> using LightQuery

julia> 1 |> (@_ _ + 1)
2

julia> map((@_ __ - _), (1, 2), (2, 1))
(1, -1)
```
"""
macro _(body::Expr)
    anonymize(body, @__LINE__, @__FILE__) |> esc
end

plain_argument(argument, line, file) =
    Expr(:tuple, anonymize(argument, line, file), quot(argument))

handle_keywords(argument::Expr, line, file) =
    if argument.head == :kw
        Expr(:kw,
            argument.args[1],
            handle_keywords(argument.args[2], line, file)
        )
    else
        plain_argument(argument, line, file)
    end
handle_keywords(argument, line, file) = plain_argument(argument, line, file)

is_parameter(argument::Expr) = argument.head == :parameters
is_parameter(argument) = false

build_call(afunction, arguments, parity, line, file) =
    if length(arguments) >= parity
        first_argument = arguments[1]
        if is_parameter(first_argument)
            Expr(:call,
                afunction,
                Expr(:parameters, handle_keywords.(first_argument.args, line, file)...),
                arguments[2:parity+1]...,
                handle_keywords.(arguments[parity+2:end], line, file)...
            )
        else
            Expr(:call,
                afunction,
                arguments[1:parity]...,
                handle_keywords.(arguments[parity+1:end], line, file)...
            )
        end
    else
        error("Expecting at least $parity argument(s)")
    end

anonymize_arguments(atail, line, file) =
    if @capture atail numberedfunction_(arguments__)
        string_function = string(numberedfunction)
        parity = tryparse(Int, string(string_function[end]))
        if parity == nothing
            atail
        else
            build_call(
                Symbol(chop(string_function)),
                arguments, parity, line, file
            )
        end
    else
        atail
    end

query(body, line, file)  =
    if @capture body head_ |> atail_
        Expr(:call,
            anonymize(anonymize_arguments(atail, line, file), line, file),
            query(head, line, file)
        )
    else
        body
    end

export @query
"""
    macro query(body::Expr)

Query your code. If body is a chain `head_ |> tail_`, recur on
head. If tail is a function call, and the function ends
with a number (the parity), anonymize and quote arguments past that parity.
Either way, anonymize the whole tail, then call it on head.

```jldoctest
julia> using LightQuery

julia> call(source1, source2, (anonymous, quoted)) =
            anonymous(source1, source2), quoted;

julia> @query 1 |> (_ - 2) |> abs(_) |> call2(_, 2, _ + __)
(3, :(_ + __))

julia> function call_keywords(source1; anonymous_quoted)
            anonymous, quoted = anonymous_quoted
            anonymous(source1), quoted
        end;

julia> @query 1 |> call_keywords1(_, anonymous_quoted = _ + 1)
(2, :(_ + 1))

julia> @query 1 |> call_keywords1(_; anonymous_quoted = _ + 1)
(2, :(_ + 1))
```
"""
macro query(body)
    line = @__LINE__
    file = @__FILE__
    query(body, line, file) |> esc
end

end
