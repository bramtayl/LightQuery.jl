const Some{It} = Tuple{It, Vararg{It}}

struct Name{name} end

const Named = Tuple{Name, Any}

@inline Name(name) = Name{name}()

show(io::IO, ::Name{name}) where {name} = print(io, name)

@generated split_names(::Val{some_names}) where {some_names} =
    map(Name, some_names)

matches(::Tuple{Name{name}, Any}, ::Tuple{Name{name}, Any}) where {name} = true
matches(::Tuple{Name{name}, Any}, ::Name{name}) where {name} = true
matches(apple, orange) = false

value(named::Named) = named[2]

get_pair(named::Tuple{}, name::Name) = error("Cannot find $name")
function get_pair(named::Some{Named}, name::Name)
    first_pair = named[1]
    if matches(first_pair, name)
        first_pair
    else
        get_pair(tail(named), name)
    end
end

getindex(named::Some{Named}, name::Name) = value(get_pair(named, name))

(name::Name)(named::Some{Named}) = getindex(named, name)
(::Name{name})(something) where {name} = getproperty(something, name)

getproperty(named::Some{Named}, name::Symbol) = getindex(named, Name{name}())

getindex(named::Some{Named}, some_names::Some{Name}) =
    get_pair(named, first(some_names)), getindex(named, tail(some_names))...
getindex(named::Some{Named}, some_names::Tuple{}) = ()
getindex(them::Tuple, some_names::Some{Name}) = map(tuple, some_names, them)

(some_names::Some{Name})(named::Some{Named}) = getindex(named, some_names)
(some_names::Some{Name})(them::Tuple) = map(tuple, some_names, them)

@generated isless(::Name{name1}, ::Name{name2}) where {name1, name2} =
    isless(name1, name2)

make_names(something) = something
make_names(symbol::QuoteNode) = Name{symbol.value}()
make_names(expression::Expr) =
    if @capture expression data_.name_
        expression
    elseif @capture expression name_Symbol = value_
        :(($(Name{name}()), $(make_names(value))))
    else
        Expr(expression.head, map(make_names, expression.args)...)
    end

"""
    macro name(something)

Replace symbols with `Name`s, and `NamedTuples` with [`named_tuple`](@ref)s.
`Name`s can be used as indices, functions, or properties.

```jldoctest
julia> using LightQuery

julia> @name :a
a

julia> data = @name (a = 1, b = 2, c = 3)
((a, 1), (b, 2), (c, 3))

julia> @name data[:a]
1

julia> @name (:a)(data)
1

julia> data.a
1

julia> @name data[(:a, :b)]
((a, 1), (b, 2))

julia> @name (1, 2)[(:a, :b)]
((a, 1), (b, 2))

julia> @name (:a, :b)(data)
((a, 1), (b, 2))

julia> @name (:a, :b)((1, 2))
((a, 1), (b, 2))
```
"""
macro name(something)
    esc(make_names(something))
end
export @name

"""
    named_tuple(anything)

Coerce `anything` to a `named_tuple`. For performance with structs, define and `@inline` propertynames.

```jldoctest
julia> using LightQuery

julia> data = @name ((a = 1, b = 2))
((a, 1), (b, 2))

julia> struct MyType
            a::Int
            b::Int
        end

julia> @inline Base.propertynames(::MyType) = (:a, :b);

julia> named_tuple(MyType(1, 2))
((a, 1), (b, 2))
```
"""
function named_tuple(anything)
    some_names = split_names(Val{Tuple(propertynames(anything))}())
    map(name -> (name, name(anything)), some_names)
end
export named_tuple

@inline flatten_unrolled(::Tuple{}) = ()
@inline flatten_unrolled(them::Some{Any}) =
    first(them)..., flatten_unrolled(tail(them))...

@inline if_not_in(it, ::Tuple{}) = (it,)
@inline if_not_in(it, them::Some{Any}) =
    if matches(it, first(them))
        ()
    else
        if_not_in(it, tail(them))
    end

@inline diff_unrolled(::Tuple{}, less) = ()
@inline diff_unrolled(more::Some{Any}, less) =
    if_not_in(first(more), less)..., diff_unrolled(tail(more), less)...
"""
    remove(data, names...)

Remove `names` from `data`.

```jldoctest
julia> using LightQuery

julia> @name remove((a = 1, b = 2, c = 3), :b)
((a, 1), (c, 3))
```
"""
function remove(data, names...)
    diff_unrolled(data, names)
end
export remove

"""
    transform(data, assignments...)

Merge `assignments` into `data`, overwriting old values.

```jldoctest
julia> using LightQuery

julia> @name transform((a = 1, b = 2), a = 3)
((b, 2), (a, 3))
```
"""
function transform(data, assignments...)
    diff_unrolled(data, assignments)..., assignments...
end
export transform

"""
    rename(data, assignments...)

Rename `data`.

```jldoctest
julia> using LightQuery

julia> @name rename((a = 1, b = 2), c = :a)
((b, 2), (c, 1))
```
"""
function rename(data, assignments...)
    (
        diff_unrolled(data, map(value, assignments))...,
        map(
            tuple,
            map(first, assignments),
            map(value, data[map(value, assignments)])
        )...
    )
end

export rename

"""
    gather(data; assignments...)

For each `key => value` pair in `assignments`, gather the names in `value` into a single `key`. Inverse of [`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> @name gather((a = 1, b = 2, c = 3), d = (:a, :c))
((b, 2), (d, ((a, 1), (c, 3))))
```
"""
gather(data, assignments...) = (
    diff_unrolled(data, flatten_unrolled(map(value, assignments)))...,
    map(
        tuple,
        map(first, assignments),
        map(chunk -> data[chunk], map(value, assignments))
    )...
)
export gather

"""
    spread(data, names...)

Unnest nested [`named_tuple`](@ref)s. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> @name spread((b = 2, d = (a = 1, c = 3)), :d)
((b, 2), (a, 1), (c, 3))
```
"""
spread(data, names...) =
    diff_unrolled(data, names)..., flatten_unrolled(map(value, data[names]))...
export spread
