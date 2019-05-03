struct Name{x} end

get_property(row, ::Name{name}) where {name} = getproperty(row, name)

const Named = Tuple{Name, Any}

show(output::IO, ::Name{name}) where {name} = print(output, '`', name, '`')

@inline matches(::Tuple{Name{name}, Any}, ::Tuple{Name{name}, Any}) where {name} = true
@inline matches(::Tuple{Name{name}, Any}, ::Name{name}) where {name} = true
@inline matches(apple, orange) = false

get_index(row::Tuple{}, name::Name) = error("Cannot find $name")
function get_index(row, name::Name)
    name_value_1 = row[1]
    if matches(name_value_1, name)
        name_value_1
    else
        get_index(tail(row), name)
    end
end
getindex(row::Some{Named}, name::Name) =
    get_index(row, name)[2]
(name::Name)(row::Some{Named}) = row[name]
get_property(row::Some{Named}, name::Name) = row[name]

getindex(row::Some{Named}, some_names::Some{Name}) =
    partial_map(get_index, row, some_names)
(some_names::Some{Name})(row::Some{Named}) = row[some_names]

(some_names::Some{Name})(values::Tuple) = map(tuple, some_names, values)
getindex(values::Tuple, some_names::Some{Name}) = some_names(values)

isless(::Name{name1}, ::Name{name2}) where {name1, name2} = isless(name1, name2)

make_names(other) = other
make_names(symbol::QuoteNode) = Name{symbol.value}()
make_names(code::Expr) =
    if @capture code row_.name_
        Expr(:call, get_property, make_names(row), Name{name}())
    elseif @capture code name_Symbol = value_
        Expr(:tuple, Name{name}(), make_names(value))
    else
        Expr(code.head, map(make_names, code.args)...)
    end

"""
    macro name(code)

Switch to named tuples based on typed `Name`s. `Name`s can be used as indices,
keywords, functions, or properties.

```jldoctest
julia> using LightQuery

julia> @name :a
`a`

julia> row = @name (a = 1, b = 2, c = 3)
((`a`, 1), (`b`, 2), (`c`, 3))

julia> @name row[:a]
1

julia> @name (:a)(row)
1

julia> @name row.a
1

julia> @name row[(:a, :b)]
((`a`, 1), (`b`, 2))

julia> @name (1, 2)[(:a, :b)]
((`a`, 1), (`b`, 2))

julia> @name (:a, :b)(row)
((`a`, 1), (`b`, 2))

julia> @name (:a, :b)((1, 2))
((`a`, 1), (`b`, 2))
```
"""
macro name(code)
    esc(make_names(code))
end
export @name

if_not_in(it, ::Tuple{}) = (it,)
if_not_in(it, them) =
    if matches(it, them[1])
        ()
    else
        if_not_in(it, tail(them))
    end

diff_unrolled(::Tuple{}, less) = ()
diff_unrolled(more, less) =
    if_not_in(first(more), less)..., diff_unrolled(tail(more), less)...

"""
    remove(row, old_names...)

Remove `old_names` from `row`.

```jldoctest
julia> using LightQuery

julia> @name remove((a = 1, b = 2, c = 3), :b)
((`a`, 1), (`c`, 3))
```
"""
remove(row, old_names...) = diff_unrolled(row, old_names)
export remove

"""
    transform(row, name_values...)

Merge `name_values` into `row`, overwriting old values.

```jldoctest
julia> using LightQuery

julia> @name transform((a = 1, b = 2), a = 3)
((`b`, 2), (`a`, 3))
```
"""
transform(row, name_values...) =
    diff_unrolled(row, name_values)..., name_values...
export transform

"""
    rename(row, new_name_old_names...)

Rename `row`.

```jldoctest
julia> using LightQuery

julia> @name rename((a = 1, b = 2), c = :a)
((`b`, 2), (`c`, 1))
```
"""
rename(row, new_name_old_names...) =
    diff_unrolled(row, map(second, new_name_old_names))...,
    partial_map(
        (row, new_name_old_name) -> (
            first(new_name_old_name),
            row[second(new_name_old_name)]
        ),
        row, new_name_old_names
    )...

export rename

"""
    gather(row, new_name_old_names...)

For each `new_name, old_names` pair in `new_name_old_names`, gather the `old_names` into a single `new_name`. Inverse of [`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> @name gather((a = 1, b = 2, c = 3), d = (:a, :c))
((`b`, 2), (`d`, ((`a`, 1), (`c`, 3))))
```
"""
gather(row, new_name_old_names...) =
    diff_unrolled(row, flatten_unrolled(map(second, new_name_old_names)))...,
    partial_map(
        (row, new_name_old_name) -> (
            new_name_old_name[1],
            row[new_name_old_name[2]]
        ),
        row, new_name_old_names
    )...
export gather

"""
    spread(row, some_names...)

Unnest nested named tuples. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> @name spread((b = 2, d = (a = 1, c = 3)), :d)
((`b`, 2), (`a`, 1), (`c`, 3))
```
"""
spread(row, some_names...) =
    diff_unrolled(row, some_names)...,
    flatten_unrolled(map(second, row[some_names]))...
export spread

"""
    named_schema(table)

Get the `named_schema` of a `table`. Can be used as a function.

```jldoctest
julia> using LightQuery

julia> import CSV

julia> file = CSV.File("test.csv");

julia> f = named_schema(file)
((`a`, Val{Union{Missing, Int64}}()), (`b`, Val{Union{Missing, Float64}}()))

julia> f(first(file))
((`a`, 1), (`b`, 1.0))
```
"""
named_schema(table) = named_schema(schema(table))

export named_schema

function named_schema(::Schema{some_names, Values}) where {some_names, Values}
    @inline inner(i) = Name{some_names[i]}(), Val{fieldtype(Values, i)}()
    ntuple(inner, Val{length(some_names)}())
end

function get_index(row, name_val_type::Tuple{Name, Val{AType}}) where {AType}
    name = name_val_type[1]
    name, get_property(row, name)::AType
end
(name_val_type::Tuple{Name, Val})(row) = get_index(row, name_val_type)

get_index(row, name_val_types::Some{Tuple{Name, Val}}) =
    partial_map(get_index, row, name_val_types)

(name_val_types::Some{Tuple{Name, Val}})(row) = get_index(row, name_val_types)
