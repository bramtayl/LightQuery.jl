struct Name{name}
end

"""
    Name(name)

Create a typed `Name`. Inverse of [`unname`](@ref)

```jlodctest
julia> using LightQuery

julia> Name(:a)
`a`
```
"""
@pure Name(name) = Name{name}()
export Name

"""
    unname(::Name{name}) where name

Inverse of [`Name`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred unname(Name(:a))
:a
```
"""
@inline unname(::Name{name}) where name = name
export unname

show(output::IO, ::Name{name}) where {name} = print(output, '`', name, '`')

const Named{name} = Tuple{Name{name}, Any}

recursive_get(initial, name) = throw(BoundsError(initial, (name,)))
function recursive_get(initial, name, (check_name, value), rest...)
    if name === check_name
        value
    else
        recursive_get(initial, name, rest...)
    end
end

(::Name{name})(object) where {name} = getproperty(object, name)
(name::Name)(data::Some{Named}) = recursive_get(data, name, data...)

get_pair(data, name) = name, name(data)

(some_names::Some{Name})(data) = partial_map(get_pair, data, some_names)
(::Tuple{})(::Some{Named}) = ()

@inline isless(::Name{name1}, ::Name{name2}) where {name1, name2} =
    isless(name1, name2)

# to override recusion limit on constant propagation
@pure to_Names(some_names::Some{Symbol}) = map_unrolled(Name, some_names)
to_Names(them) = map_unrolled(Name, Tuple(them))

NamedTuple(data::Some{Named}) = NamedTuple{map_unrolled(unname ∘ key, data)}(
    map_unrolled(value, data)
)

code_with_names(other) = other
code_with_names(symbol::QuoteNode) = Name{symbol.value}()
code_with_names(code::Expr) =
    if @capture code data_.name_
        Expr(:call, Name{name}(), code_with_names(data))
    elseif @capture code name_Symbol = value_
        Expr(:tuple, Name{name}(), code_with_names(value))
    else
        Expr(code.head, map(code_with_names, code.args)...)
    end

"""
    macro name(code)

Switch to [`named_tuple`](@ref)s.

```jldoctest name
julia> using LightQuery

julia> using Test: @inferred

julia> data = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```

based on typed `Name`s.

```jldoctest name
julia> @name :a
`a`
```

`Name`s can be used as properties

```jldoctest name
julia> @name @inferred data.c
1

julia> @name data.g
ERROR: BoundsError: attempt to access ((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
[...]
```

and selector functions.

```jldoctest name
julia> @name @inferred (:c)(data)
1
```

Multiple names can be used as selector functions

```jldoctest name
julia> @name @inferred (:c, :f)(data)
((`c`, 1), (`f`, 1.0))
```

You can also convert back to `NamedTuple`s.

```jldoctest name
julia> @inferred NamedTuple(data)
(a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
```
"""
macro name(code)
    esc(code_with_names(code))
end
export @name

"""
    named_tuple(data)

Convert `data` to a `named_tuple` (see [`@name`](@ref)).

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
named_tuple(data) = to_Names(propertynames(data))(data)
export named_tuple

@inline haskey(data::Some{Named}, name::Name) =
    is_empty(if_not_in(map_unrolled(key, data), name))
@inline haskey(data, ::Name{name}) where {name} = hasproperty(data, name)

"""
    remove(data, old_names...)

Remove `old_names` from `data`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))

julia> @name @inferred remove(data, :c, :f)
((`a`, 1), (`b`, 1.0), (`d`, 1.0), (`e`, 1))
```
"""
remove(data, old_names...) =
    diff_unrolled(map_unrolled(key, data), old_names)(data)

export remove

"""
    transform(data, assignments...)

Merge `assignments` into `data`, overwriting old values.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))

julia> @name @inferred transform(data, c = 2.0, f = 2, g = 1, h = 1.0)
((`a`, 1), (`b`, 1.0), (`d`, 1.0), (`e`, 1), (`c`, 2.0), (`f`, 2), (`g`, 1), (`h`, 1.0))
```
"""
transform(data, assignments...) =
    remove(data, map_unrolled(key, assignments)...)..., assignments...
export transform

merge_2(data1, data2) = transform(data1, data2...)
merge(datas::Some{Named}...) = reduce_unrolled(merge_2, datas...)

rename_one(data, (new_name, old_name)) = new_name, old_name(data)
"""
    rename(data, new_name_old_names...)

Rename `data`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))

julia> @name @inferred rename(data, c2 = :c, f2 = :f)
((`a`, 1), (`b`, 1.0), (`d`, 1.0), (`e`, 1), (`c2`, 1), (`f2`, 1.0))
```
"""
rename(data, new_name_old_names...) =
    remove(data, map_unrolled(value, new_name_old_names)...)...,
    partial_map(rename_one, data, new_name_old_names)...
export rename

"""
    gather(data, new_name_old_names...)

For each `new_name, old_names` pair in `new_name_old_names`, gather the `old_names` into a single `new_name`. Inverse of [`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> data = @name (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))

julia> @name @inferred gather(data, g = (:b, :e), h = (:c, :f))
((`a`, 1), (`d`, 1.0), (`g`, ((`b`, 1.0), (`e`, 1))), (`h`, ((`c`, 1), (`f`, 1.0))))
```
"""
gather(data, new_name_old_names...) =
    remove(
        data,
        flatten_unrolled(map_unrolled(value, new_name_old_names)...)...
    )...,
    partial_map(rename_one, data, new_name_old_names)...
export gather

"""
    spread(data, some_names...)

Unnest nested named tuples. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> gathered = @name (a = 1, d = 1.0, g = (b = 1.0, e = 1), h = (c = 1, f = 1.0))
((`a`, 1), (`d`, 1.0), (`g`, ((`b`, 1.0), (`e`, 1))), (`h`, ((`c`, 1), (`f`, 1.0))))

julia> @name @inferred spread(gathered, :g, :h)
((`a`, 1), (`d`, 1.0), (`b`, 1.0), (`e`, 1), (`c`, 1), (`f`, 1.0))
```
"""
spread(data, some_names...) =
    remove(data, some_names...)...,
    flatten_unrolled(map_unrolled(value, some_names(data))...)...
export spread

"""
    struct Apply{Names}

Apply [`Name`](@ref)s to unnamed values.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @name @inferred Apply((:a, :b, :c, :d, :e, :f))((1, 1.0, 1, 1.0, 1, 1.0))
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```
"""
struct Apply{Names <: Some{Name}}
    names::Names
end
export Apply

(apply::Apply)(them) = map_unrolled(tuple, apply.names, them)

"""
    struct Column{name, type, position}

Contains the name, type, and position of each column. Useful for type stable
iteration of rows. See example in [`to_Columns`](@ref).
"""
struct Column{name, type, position}
end
export Column

@pure Column(name, type, position) = Column{name, type, position}()

(a_column::Column{name, type, position})(data::Row) where {name, type, position} =
    getcell(getfile(data), type, position, getrow(data))::type

get_pair(data::Row, column::Column{name}) where {name} =
    name, column(data)
(columns::Some{Column})(data) = partial_map(get_pair, data, columns)

@inline Column_at(::Schema{Names, Types}, index) where {Names, Types} =
    Column(Name{Names[index]}(), fieldtype(Types, index), index)

"""
    to_Columns(::Tables.Schema)

Get the [`Column`](@ref)s in a schema. [`Column`](@ref)s can be used as a type stable selector function.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> using CSV: File

julia> using Tables: schema

julia> test = File("test.csv")
CSV.File("test.csv"):
Size: 1 x 6
Tables.Schema:
 :a  Int64
 :b  Float64
 :c  Int64
 :d  Float64
 :e  Int64
 :f  Float64

julia> template = @inferred to_Columns(schema(test))
(Column{`a`,Int64,1}(), Column{`b`,Float64,2}(), Column{`c`,Int64,3}(), Column{`d`,Float64,4}(), Column{`e`,Int64,5}(), Column{`f`,Float64,6}())

julia> @inferred template(first(test))
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```
"""
to_Columns(a_schema::Schema{Names}) where Names =
    ntuple(let a_schema = a_schema
        @inline Column_at_capture(index) = Column_at(a_schema, index)
    end, Val{length(Names)}())

export to_Columns
