struct Name{name} end

"""
    Name(name)

Create a typed `Name`. Inverse of [`unname`](@ref)

```jlodctest
julia> using LightQuery

julia> Name(:a)
`a`
```
"""
@pure function Name(name)
    Name{name}()
end
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
@inline function unname(::Name{name}) where {name}
    name
end
export unname

@inline function show(output::IO, ::Name{name}) where {name}
    print(output, '`', name, '`')
end

const Named{name} = Tuple{Name{name},Any}

@inline function recursive_get(initial, name)
    throw(BoundsError(initial, (name,)))
end
@inline function recursive_get(initial, name, (check_name, value), rest...)
    if name === check_name
        value
    else
        recursive_get(initial, name, rest...)
    end
end

@inline function (::Name{name})(object) where {name}
    getproperty(object, name)
end
@inline function (name::Name)(data::Some{Named})
    recursive_get(data, name, data...)
end

@inline function get_pair(data, name)
    name, name(data)
end

@inline function (some_names::Some{Name})(data)
    partial_map(get_pair, data, some_names)
end
@inline function (::Tuple{})(::Some{Named})
    ()
end

@inline function isless(::Name{name1}, ::Name{name2}) where {name1,name2}
    isless(name1, name2)
end

# to override recusion limit on constant propagation
@pure function to_Names(some_names::Some{Symbol})
    map_unrolled(Name, some_names)
end
@inline function to_Names(them)
    map_unrolled(Name, Tuple(them))
end

@inline function NamedTuple(data::Some{Named})
    NamedTuple{map_unrolled(unname ∘ key, data)}(map_unrolled(value, data))
end

function code_with_names(other)
    other
end
function code_with_names(symbol::QuoteNode)
    Name{symbol.value}()
end
function code_with_names(code::Expr)
    if @capture code data_.name_
        Expr(:call, Name{name}(), code_with_names(data))
    elseif @capture code name_Symbol = value_
        Expr(:tuple, Name{name}(), code_with_names(value))
    else
        Expr(code.head, map(code_with_names, code.args)...)
    end
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
@inline function named_tuple(data)
    to_Names(propertynames(data))(data)
end
export named_tuple

@inline function haskey(data::Some{Named}, name::Name)
    in_unrolled(name, map_unrolled(key, data)...)
end
@inline function haskey(data, ::Name{name}) where {name}
    hasproperty(data, name)
end

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
@inline function remove(data, old_names...)
    diff_unrolled(old_names, map_unrolled(key, data)...)(data)
end

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
@inline function transform(data, assignments...)
    remove(data, map_unrolled(key, assignments)...)..., assignments...
end
export transform

@inline function merge_2(data1, data2)
    transform(data1, data2...)
end
@inline function merge(datas::Some{Named}...)
    reduce_unrolled(merge_2, datas...)
end

@inline function rename_one(data, (new_name, old_name))
    new_name, old_name(data)
end
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
@inline function rename(data, new_name_old_names...)
    remove(data, map_unrolled(value, new_name_old_names)...)...,
    partial_map(rename_one, data, new_name_old_names)...
end
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
@inline function gather(data, new_name_old_names...)
    remove(data, flatten_unrolled(map_unrolled(value, new_name_old_names)...)...)...,
    partial_map(rename_one, data, new_name_old_names)...
end
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
@inline function spread(data, some_names...)
    remove(data, some_names...)...,
    flatten_unrolled(map_unrolled(value, some_names(data))...)...
end
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
struct Apply{Names<:Some{Name}}
    names::Names
end
export Apply

@inline function (apply::Apply)(them)
    map_unrolled(tuple, apply.names, them)
end

struct InRow{name,AColumn}
    column::AColumn
end
@inline function InRow{name}(column::AColumn) where {name,AColumn}
    InRow{name,AColumn}(column)
end
@inline function (in_row::InRow)(row::Row)
    in_row.column[getrow(row)]
end
@inline function get_pair(row::Row, in_row::InRow{name}) where {name}
    Name{name}(), in_row(row)
end
@inline function (in_rows::Some{InRow})(data)
    partial_map(get_pair, data, in_rows)
end

"""
    row_info(::CSV.File)

Get row info for the CSV file. Can be used as a type stable selector function.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> using CSV: File

julia> test = File("test.csv");

julia> template = row_info(test)
(LightQuery.InRow{:a,CSV.Column{Int64,Int64}}([1]), LightQuery.InRow{:b,CSV.Column{Float64,Float64}}([1.0]), LightQuery.InRow{:c,CSV.Column{Int64,Int64}}([1]), LightQuery.InRow{:d,CSV.Column{Float64,Float64}}([1.0]), LightQuery.InRow{:e,CSV.Column{Int64,Int64}}([1]), LightQuery.InRow{:f,CSV.Column{Float64,Float64}}([1.0]))

julia> @inferred template(first(test))
((`a`, 1), (`b`, 1.0), (`c`, 1), (`d`, 1.0), (`e`, 1), (`f`, 1.0))
```
"""
@noinline function row_info(file::File)
    ((InRow{name}(getcolumn(file, name)) for name in propertynames(file))...,)
end

export row_info
