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
@inline Name(name) = Name{name}()
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

const Named{name} = Tuple{Name{name}, Any}

recursive_get(initial, name) = throw(BoundsError(initial, (name,)))
function recursive_get(initial, name, (check_name, value), rest...)
    if name === check_name
        value
    else
        recursive_get(initial, name, rest...)
    end
end

getindex(row, ::Name{name}) where {name} = getproperty(row, name)
getindex(row::Some{Named}, name::Name) = recursive_get(row, name, row...)

get_pair(row, name) = name, row[name]
getindex(row, some_names::Some{Name}) = partial_map(get_pair, row, some_names)
getindex(row::Some{Named}, ::Tuple{}) = ()

(name::Name)(row) = row[name]
(some_names::Some{Name})(row) = row[some_names]

@inline isless(::Name{name1}, ::Name{name2}) where {name1, name2} =
    isless(name1, name2)

# to override recusion limit on constant propagation
@pure to_Names(some_names::Some{Symbol}) = map_unrolled(Name, some_names)

NamedTuple(row::Some{Named}) = NamedTuple{map_unrolled(unname ∘ key, row)}(
    map_unrolled(value, row)
)

code_with_names(other) = other
code_with_names(symbol::QuoteNode) = Name{symbol.value}()
code_with_names(code::Expr) =
    if @capture code row_.name_
        Expr(:ref, code_with_names(row), Name{name}())
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

julia> @name row.g
ERROR: BoundsError: attempt to access ((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
[...]
```

indices

```jldoctest name
julia> @name @inferred row[:c]
1
```

and selector functions.

```jldoctest name
julia> @name @inferred (:c)(row)
1
```

Multiple names can be used as indices

```jldoctest name
julia> @name @inferred row[(:c, :f)]
((`c`, 1), (`f`, 1.0))
```

and selector functions

```jldoctest name
julia> @name @inferred (:c, :f)(row)
((`c`, 1), (`f`, 1.0))
```

You can also convert back to `NamedTuple`s.

```jldoctest name
julia> @inferred NamedTuple(row)
(a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
```
"""
macro name(code)
    esc(code_with_names(code))
end
export @name

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
named_tuple(row) = row[to_Names(propertynames(row))]
export named_tuple

@inline haskey(row::Some{Named}, name::Name) =
    isempty(if_not_in(map_unrolled(key, row), name))
@inline haskey(row, ::Name{name}) where {name} = hasproperty(row, name)

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
remove(row, old_names...) =
    row[diff_unrolled(map_unrolled(key, row), old_names)]

old_names = @name (:c, :f)

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
    remove(row, map_unrolled(key, assignments)...)..., assignments...
export transform

merge_2(row1, row2) = transform(row1, row2...)
merge(rows::Some{Named}...) = reduce_unrolled(merge_2, rows...)

rename_at(row, (new_name, old_name)) = new_name, row[old_name]
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
    remove(row, map_unrolled(value, new_name_old_names)...)...,
    partial_map(rename_at, row, new_name_old_names)...
export rename

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
    remove(
        row,
        flatten_unrolled(map_unrolled(value, new_name_old_names)...)...
    )...,
    partial_map(rename_at, row, new_name_old_names)...
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
    remove(row, some_names...)...,
    flatten_unrolled(map_unrolled(value, row[some_names])...)...
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

getindex(row::Row, ::Column{name, type, position}) where {name, type, position} =
    getcell(getfile(row), type, position, getrow(row))::type
get_pair(row::Row, column::Column{name}) where {name} =
    Name{name}(), row[column]
getindex(row, some_columns::Some{Column}) =
    partial_map(get_pair, row, some_columns)

(a_column::Column)(row::Row) = row[a_column]
(some_columns::Some{Column})(row) = row[some_columns]

"""
    to_Columns(::Tables.Schema)

Get the [`Column`](@ref)s in a schema. Useful for type stable iteration of rows.

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

julia> template = to_Columns(schema(test))
(Column{:a,Int64,1}(), Column{:b,Float64,2}(), Column{:c,Int64,3}(), Column{:d,Float64,4}(), Column{:e,Int64,5}(), Column{:f,Float64,6}())

julia> @inferred template(first(test))
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```
"""
function to_Columns(::Schema{Names, Types}) where {Names, Types}
    @inline Column_at(index) =
        Column{Names[index], fieldtype(Types, index), index}()
    ntuple(Column_at, Val{length(Names)}())
end
export to_Columns
