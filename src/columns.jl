struct Name{name}
    Name{name}() where {name} = new{name::Symbol}()
end

"""
    Name(symbol::Symbol)

Create a typed `Name`. Inverse of [`unname`](@ref)

```jlodctest
julia> using LightQuery

julia> Name(:a)
`a`
```
"""
@inline Name(symbol::Symbol) = Name{symbol}()

export Name

"""
    unname(::Name{name}) where name

Inverse of [`Name`](@ref).

```jldoctest
julia> using LightQuery

julia> unname(Name(:a))
:a
```
"""
@inline unname(::Name{name}) where name = name
export unname

show(output::IO, ::Name{name}) where {name} = print(output, '`', name, '`')

get_name(row, ::Name{name}) where {name} = getproperty(row, name)

const Named{name} = Tuple{Name{name}, Any}

@inline name_matches(::Named{name}, ::Named{name}) where {name} = true
@inline name_matches(::Named{name}, ::Name{name}) where {name} = true
@inline name_matches(::Name{name}, ::Named{name}) where {name} = true
@inline name_matches(apple, orange) = false

get_pair(row::Tuple{}, name::Name) = error("Cannot find $name")
function get_pair(row::Some{Named}, name::Name)
    first_pair = first(row)
    if name_matches(first_pair, name)
        first_pair
    else
        get_pair(tail(row), name)
    end
end
get_pair(row, name::Name) = name, get_name(row, name)
function get_pair(row, template::Tuple{Name, Val{AType}}) where AType
    name = first(template)
    name, get_name(row, name)::AType
end
(template::Tuple{Name, Any})(row) = get_pair(row, template)

getindex(row::Some{Named}, name::Name) = value(get_pair(row, name))
get_name(row::Some{Named}, name::Name) = row[name]
(name::Name)(row) = get_name(row, name)


getindex(row::Some{Named}, some_names::Some{Name}) =
    partial_map(get_pair, row, some_names)
(some_names::Some{Name})(row::Some{Named}) = row[some_names]

(some_names::Some{Name})(values::Tuple) = map(tuple, some_names, values)

(templates::Some{Named})(row) =
    partial_map(get_pair, row, templates)

@pure isless(::Name{name1}, ::Name{name2}) where {name1, name2} =
    isless(name1, name2)

make_names(other) = other
make_names(symbol::QuoteNode) = Name{symbol.value}()
make_names(code::Expr) =
    if @capture code row_.name_
        Expr(:call, get_name, make_names(row), Name{name}())
    elseif @capture code name_Symbol = value_
        Expr(:tuple, Name{name}(), make_names(value))
    else
        Expr(code.head, map(make_names, code.args)...)
    end

"""
    macro name(code)

Switch to [`named_tuple`](@ref)s.

```jldoctest name
julia> using LightQuery

julia> using Test: @inferred

julia> row = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```

based on typed `Name`s.

```jldoctest name
julia> @name :a
`a`
```

`Name`s can be used as properties

```jldoctest name
julia> @name @inferred row.c
1
```

indices

```jldoctest name
julia> @name @inferred row[:c]
1
```

And selector functions.

```jldoctest name
julia> @name @inferred (:c)(row)
1
```

Multiple names can be used as indices

```jldoctest name
julia> @name @inferred row[(:c, :f)]
((`c`, 1), (`f`, 1.0))
```

selector functions

```jldoctest name
julia> @name @inferred (:c, :f)(row)
((`c`, 1), (`f`, 1.0))
```

and also to create new names

```jldoctest name
julia> @name @inferred (:a, :b)((1, 1.0))
((`a`, 1), (`b`, 1.0))
```

You can also convert back to `NamedTuple`s.

```jldoctest name
julia> @inferred NamedTuple(row)
(a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
```
"""
macro name(code)
    esc(make_names(code))
end
export @name

@pure get_names(some_names::NTuple{N, Symbol}) where {N} = map(Name, some_names)

"""
    named_tuple(row)

Convert `row` to a `named_tuple` (see [`@name`](@ref)).

```jldoctest named_tuple
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred named_tuple((a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0))
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```

For stability working with arbitrary `struct`s, `propertynames` must constant propagate.

```jldoctest named_tuple
julia> struct MyType
            a::Int
            b::Float64
            c::Int
            d::Float64
            e::Int
            f::Float64
        end

julia> import Base: propertynames

julia> @inline propertynames(::MyType) = (:a, :b, :c, :d, :e, :f);

julia> @inferred named_tuple(MyType(1, 1.0, 1, 1.0, 1, 1.0))
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```
"""
named_tuple(row) =
    partial_map(get_pair, row, get_names(propertynames(row)))

export named_tuple

"""
    named_tuple(::Schema)

Convert a `Tables.Schema` to a `named_tuple` template.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> using CSV: File

julia> using Tables: schema

julia> file = File("test.csv");

julia> template = named_tuple(schema(file))
((`a`, Val{Int64}()), (`b`, Val{Float64}()), (`c`, Val{Int64}()), (`d`, Val{Float64}()), (`e`, Val{Int64}()), (`f`, Val{Float64}()))

julia> @inferred template(first(file))
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```
"""
named_tuple(::Schema{some_names, Values}) where {some_names, Values} =
    map(tuple, get_names(some_names), val_fieldtypes_or_empty(Values))

@inline unname_all(some_names::Some{Name}) = map(unname, some_names)
NamedTuple(row) = NamedTuple{unname_all(map(key, row))}(map(value, row))

if_name_not_in(it, ::Tuple{}) = (it,)
if_name_not_in(it, them::Some{Any}) =
    if name_matches(it, first(them))
        ()
    else
        if_name_not_in(it, tail(them))
    end

diff_names_unrolled(::Tuple{}, less) = ()
diff_names_unrolled(more::Some{Any}, less) =
    if_name_not_in(first(more), less)...,
    diff_names_unrolled(tail(more), less)...

@inline haskey(row::Some{Named}, name) = isempty(if_name_not_in(name, row))
@inline has_name(row::Some{Named}, name::Name) = haskey(row, name)
@inline has_name(row, ::Name{name}) where {name} = hasproperty(row, name)

"""
    remove(row, old_names...)

Remove `old_names` from `row`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> row = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))

julia> @name @inferred remove(row, :c, :f)
((`a`, 1), (`b`, 1.0), (`d`, 1.0), (`e`, 1))
```
"""
remove(row, old_names...) = diff_names_unrolled(row, old_names)
export remove

"""
    transform(row, assignments...)

Merge `assignments` into `row`, overwriting old values.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> row = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))

julia> @name @inferred transform(row, c = 2.0, f = 2, g = 1, h = 1.0)
((`a`, 1), (`b`, 1.0), (`d`, 1.0), (`e`, 1), (`c`, 2.0), (`f`, 2), (`g`, 1), (`h`, 1.0))
```
"""
transform(row, assignments...) =
    diff_names_unrolled(row, assignments)..., assignments...
export transform

merge_2(row1, row2) = transform(row1, row2...)
merge(rows::Some{Named}...) = reduce_unrolled(merge_2, rows...)

rename_at(row, (new_name, old_name)) = new_name, get_name(row, old_name)
"""
    rename(row, new_name_old_names...)

Rename `row`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> row = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))

julia> @name @inferred rename(row, c2 = :c, f2 = :f)
((`a`, 1), (`b`, 1.0), (`d`, 1.0), (`e`, 1), (`c2`, 1), (`f2`, 1.0))
```
"""
rename(row, new_name_old_names...) =
    diff_names_unrolled(row, map(value, new_name_old_names))...,
    partial_map(rename_at, row, new_name_old_names)...
export rename

gather_at(row, (new_name, old_names)) = new_name, row[old_names]
"""
    gather(row, new_name_old_names...)

For each `new_name, old_names` pair in `new_name_old_names`, gather the `old_names` into a single `new_name`. Inverse of [`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> row = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))

julia> @name gather(row, g = (:b, :e), h = (:c, :f))
((`a`, 1), (`d`, 1.0), (`g`, ((`b`, 1.0), (`e`, 1))), (`h`, ((`c`, 1), (`f`, 1.0))))
```
"""
gather(row, new_name_old_names...) =
    diff_names_unrolled(
        row,
        flatten_unrolled(map(value, new_name_old_names))
    )...,
    partial_map(gather_at, row, new_name_old_names)...
export gather

"""
    spread(row, some_names...)

Unnest nested named tuples. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> gathered = @name (a = 1, d = 1.0, g = (b = 1.0, e = 1), h = (c = 1, f = 1.0))
((`a`, 1), (`d`, 1.0), (`g`, ((`b`, 1.0), (`e`, 1))), (`h`, ((`c`, 1), (`f`, 1.0))))

julia> @name spread(gathered, :g, :h)
((`a`, 1), (`d`, 1.0), (`b`, 1.0), (`e`, 1), (`c`, 1), (`f`, 1.0))
```
"""
spread(row, some_names...) =
    diff_names_unrolled(row, some_names)...,
    flatten_unrolled(map(value, getindex(row, some_names)))...
export spread
