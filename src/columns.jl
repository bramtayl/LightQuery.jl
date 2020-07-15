struct Name{name} end

"""
    name_str(name)

Create a typed [`Name`](@ref).

```jldoctest
julia> using LightQuery


julia> name"a"
name"a"
```
"""
macro name_str(name)
    esc(Name{Symbol(name)}())
end
export @name_str

"""
    Name(name)

Create a typed `Name`. Inverse of [`unname`](@ref). See also [`@name_str`](@ref).

```jldoctest name
julia> using LightQuery


julia> Name(:a)
name"a"
```

`Name`s can be used as selector functions.

```jldoctest name
julia> using Test: @inferred


julia> data = (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
(a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)

julia> @inferred name"c"(data)
1
```

Multiple names can be used as selector functions

```jldoctest name
julia> @inferred (name"c", name"f")(data)
(c = 1, f = 1.0)
```

A final use for names can be as a way to construct NamedTuples from pairs.

```jldoctest name
julia> @inferred NamedTuple(((name"a", 1), (name"b", 2)))
(a = 1, b = 2)
```
"""
@pure function Name(name)
    Name{name}()
end
Name(name::Name) = name
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
function unname(::Name{name}) where {name}
    name
end
export unname

function show(output::IO, ::Name{name}) where {name}
    print(output, "name\"", name, '"')
end

const Named = Tuple{Name,Any}
const MyNamedTuple = SomeOf{Named}

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

function (::Name{name})(object) where {name}
    getproperty(object, name)
end
function (name::Name)(data::MyNamedTuple)
    if length(data) > 16
        index = findfirst(let name = name
            function ((check_name, value),)
                name === check_name
            end
        end, data)
        if index === nothing
            throw(BoundsError(data, (name,)))
        else
            data[index][2]
        end
    else
        recursive_get(initial, name, data...)
    end
end

function get_pair(data, name)
    Name(name), name(data)
end

function (some_names::SomeOf{Name})(data::MyNamedTuple)
    partial_map(get_pair, data, some_names)
end
# TODO: a version which works on all types?
function (some_names::SomeOf{Name})(data::NamedTuple)
    NamedTuple(some_names(named_tuple(data)))
end

@inline function isless(::Name{name1}, ::Name{name2}) where {name1,name2}
    isless(name1, name2)
end

# to override recusion limit on constant propagation
@pure function to_Names(some_names::SomeOf{Symbol})
    map(Name, some_names)
end
function to_Names(them)
    map(Name, Tuple(them))
end

function NamedTuple(data::MyNamedTuple)
    NamedTuple{map((function ((key, value),)
        unname(key)
    end), data)}(map(value, data))
end

function named_tuple(data)
    partial_map(get_pair, data, to_Names(propertynames(data)))
end
export MyNamedTuple

"""
    remove(data, old_names...)

Remove `old_names` from `data`.

```jldoctest
julia> using LightQuery


julia> using Test: @inferred


julia> data = (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0);


julia> @inferred remove(data, name"c", name"f")
(a = 1, b = 1.0, d = 1.0, e = 1)
```
"""
function remove(data::MyNamedTuple, old_names...)
    my_setdiff(map(key, data), old_names)(data)
end
function remove(data, old_names...)
    NamedTuple(remove(named_tuple(data), old_names...))
end

export remove

"""
    transform(data, assignments...)

Merge `assignments` into `data`, overwriting old values.

```jldoctest
julia> using LightQuery


julia> using Test: @inferred


julia> data = (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0);


julia> @inferred transform(data, c = 2.0, f = 2, g = 1, h = 1.0)
(a = 1, b = 1.0, d = 1.0, e = 1, c = 2.0, f = 2, g = 1, h = 1.0)
```
"""
function transform(data::MyNamedTuple, assignments...)
    remove(data, map(key, assignments)...)..., assignments...
end
function transform(data; assignments...)
    NamedTuple(transform(named_tuple(data), named_tuple(assignments.data)...))
end
export transform

maybe_named_tuple(something) = something
maybe_named_tuple(something::MyNamedTuple) = NamedTuple(something)

function rename_one(data, (new_name, old_name))
    new_name, maybe_named_tuple(old_name(data))
end
"""
    rename(data, new_name_old_names...)

Rename `data`.

```jldoctest
julia> using LightQuery


julia> using Test: @inferred


julia> data = (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0);


julia> @inferred rename(data, c2 = name"c", f2 = name"f")
(a = 1, b = 1.0, d = 1.0, e = 1, c2 = 1, f2 = 1.0)
```
"""
function rename(data::MyNamedTuple, new_name_old_names...)
    remove(data, map(value, new_name_old_names)...)...,
    partial_map(rename_one, data, new_name_old_names)...
end
function rename(data; new_name_old_names...)
    NamedTuple(rename(named_tuple(data), named_tuple(new_name_old_names.data)...))
end
export rename

"""
    gather(data, new_name_old_names...)

For each `new_name, old_names` pair in `new_name_old_names`, gather the `old_names` into a single `new_name`. Inverse of [`spread`](@ref).

```jldoctest
julia> using LightQuery


julia> using Test: @inferred


julia> data = (a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0);


julia> @inferred gather(data, g = (name"b", name"e"), h = (name"c", name"f"))
(a = 1, d = 1.0, g = (b = 1.0, e = 1), h = (c = 1, f = 1.0))
```
"""
function gather(data::MyNamedTuple, new_name_old_names...)
    remove(data, my_flatten(map(value, new_name_old_names))...)...,
    partial_map(rename_one, data, new_name_old_names)...
end
function gather(data; new_name_old_names...)
    NamedTuple(gather(named_tuple(data), named_tuple(new_name_old_names.data)...))
end
export gather

"""
    spread(data, some_names...)

Unnest nested named tuples. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery


julia> using Test: @inferred


julia> gathered = (a = 1, d = 1.0, g = (b = 1.0, e = 1), h = (c = 1, f = 1.0));


julia> @inferred spread(gathered, name"g", name"h")
(a = 1, d = 1.0, b = 1.0, e = 1, c = 1, f = 1.0)
```
"""
function spread(data::MyNamedTuple, some_names...)
    remove(data, some_names...)...,
    my_flatten(map((function ((name, value),)
        named_tuple(value)
    end), some_names(data)))...
end
function spread(data, some_names...)
    NamedTuple(spread(named_tuple(data), some_names...))
end

export spread

"""
    apply(names, items)

Apply [`Name`](@ref)s to unnamed values.

```jldoctest
julia> using LightQuery


julia> using Test: @inferred


julia> @inferred apply(
           (name"a", name"b", name"c", name"d", name"e", name"f"),
           (1, 1.0, 1, 1.0, 1, 1.0),
       )
(a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
```
"""
function apply(the_names, them)
    NamedTuple(map(tuple, the_names, them))
end
export apply

struct InRow{name,AColumn}
    column::AColumn
end
function InRow{name}(column::AColumn) where {name,AColumn}
    InRow{name,AColumn}(column)
end

Name(in_row::InRow{name}) where {name} = Name{name}()

function (in_row::InRow)(row::Row)
    in_row.column[getrow(row)]
end
function (in_rows::SomeOf{InRow})(data::Row)
    NamedTuple(partial_map(get_pair, data, in_rows))
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
(a = 1, b = 1.0, c = 1, d = 1.0, e = 1, f = 1.0)
```
"""
@noinline function row_info(file::File)
    ((InRow{name}(getcolumn(file, name)) for name in propertynames(file))...,)
end

export row_info
