function substitute_underscores!(underscores_to_gensyms, meta_level, other)
    other
end
function substitute_underscores!(underscores_to_gensyms, meta_level, maybe_argument::Symbol)
    if meta_level < 1 && all(isequal('_'), string(maybe_argument))
        if !haskey(underscores_to_gensyms, maybe_argument)
            underscores_to_gensyms[maybe_argument] = gensym(maybe_argument)
        end
        underscores_to_gensyms[maybe_argument]
    else
        maybe_argument
    end
end
function substitute_underscores!(underscores_to_gensyms, meta_level, code::Expr)
    # have to do this the old fashioned way because _ has a special meaning in MacroTools
    expanded_code = if code.head === :macrocall && length(code.args) === 3
        name, location, body = code.args
        if name === Symbol("@_")
            anonymous(location, body)
        elseif name === Symbol("@>")
            make_chain(location, body)
        else
            code
        end
    else
        code
    end
    head = expanded_code.head
    new_meta_level = if head == :quote
        meta_level + 1
    elseif head == :$
        meta_level - 1
    else
        meta_level
    end
    Expr(
        head,
        (
            substitute_underscores!(underscores_to_gensyms, new_meta_level, code) for
            code in expanded_code.args
        )...,
    )
end

function anonymous(location, other)
    other
end

function anonymous(location, body::Expr)
    underscores_to_gensyms = Dict{Symbol,Symbol}()
    meta_level = 0
    substituted_body = substitute_underscores!(underscores_to_gensyms, meta_level, body)
    if length(underscores_to_gensyms) == 0
        body
    else
        Expr(
            :function,
            Expr(
                :call,
                gensym("@_"),
                over(sort!(collect(underscores_to_gensyms), by = first), value)...,
            ),
            Expr(:block, Expr(:meta, :inline), location, substituted_body),
        )
    end
end

"""
    macro _(body)

Terser function syntax. The arguments are inside the `body`; the first argument is `_`, the second argument is `__`, etc. Will `@inline`.

```jldoctest anonymous
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred (@_ _ + 1)(1)
2

julia> @inferred map((@_ __ - _), (1, 2), (2, 1))
(1, -1)
```

If there are no `_` arguments, read as is.

```jldoctest anonymous
julia> (@_ x -> x + 1)(1)
2
```
"""
macro _(body)
    anonymous(__source__, body) |> esc
end
export @_

function link(location, object, call::Expr)
    underscores_to_gensyms = Dict{Symbol,Symbol}()
    meta_level = 0
    body = substitute_underscores!(underscores_to_gensyms, meta_level, call)
    Expr(:let, Expr(:(=), underscores_to_gensyms[:_], object), Expr(:block, location, body))
end
function link(location, object, call)
    Expr(:call, call, object)
end

function make_chain(location, maybe_chain)
    if @capture maybe_chain object_ |> call_
        link(location, make_chain(location, object), call)
    else
        maybe_chain
    end
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

Handles interpolations seamlessly:

```jldoctest chain
julia> @> 1 |> :(_ + \$_)
:(_ + 1)
```
"""
macro >(body)
    make_chain(__source__, body) |> esc
end
export @>
