struct Rows{Row, Dimensions, Columns, Names} <: AbstractArray{Row, Dimensions}
    columns::Columns
    names::Names
end

row_type_at(::Name, column) = Tuple{Name, eltype(column)}
row_type(names::Tuple, columns::Tuple) =
    Tuple{map(row_type_at, names, columns)...}

Rows(::Tuple{}) = Rows{Tuple{}, 0, Tuple{}, Tuple{}}((), ())
axes(::Rows{Tuple{}}) = ()
size(::Rows{Tuple{}}) = ()

function Rows(named_columns::Some{Named})
    some_names = map(key, named_columns)
    columns = map(value, named_columns)
    Rows{
        row_type(some_names, columns),
        ndims(first(columns)),
        typeof(columns),
        typeof(some_names)
    }(columns, some_names)
end

to_columns(rows::Rows) = map(tuple, rows.names, rows.columns)

@inline IteratorEltype(::Type{Rows{Row, Dimensions, Columns}}) where {Row, Dimensions, Columns} =
    _zip_iterator_eltype(Columns)
@inline IteratorSize(::Type{Rows{Row, Dimensions, Columns}}) where {Row, Dimensions, Columns} =
    _zip_iterator_size(Columns)

axes(rows::Rows, dimensions...) =
    axes(first(rows.columns), dimensions...)
size(rows::Rows, dimensions...) =
    size(first(rows.columns), dimensions...)

@inline getindex_at((columns, an_index), name) =
    name, if haskey(columns, name)
        columns[name][an_index...]
    else
        missing
    end
@inline getindex(rows::Rows, an_index...) =
    partial_map(getindex_at, (to_columns(rows), an_index), rows.names)

@inline setindex_at!((columns, an_index), (name, value)) =
    if haskey(columns, name)
        columns[name][an_index...] = value
        nothing
    end
@inline setindex!(rows::Rows, row, an_index...) =
    partial_map(setindex_at!, (to_columns(rows), an_index), row)

push_at!(columns, (name, value)) =
    if haskey(columns, name)
        push!(columns[name], value)
        nothing
    end
push!(rows::Rows, row) = partial_map(push_at!, to_columns(rows), row)

similar_at((model, dimensions), ::Val{AType}) where {AType} =
    fieldtype(AType, 1)(), similar(model, fieldtype(AType, 2), dimensions)

similar(rows::Rows{Tuple{}}, ::Type{Row}, dimensions::Dims) where Row =
    Rows(partial_map(
        similar_at,
        (1:1, 0),
        val_fieldtypes(Row)
    ))
similar(rows::Rows, ::Type{Row}, dimensions::Dims) where Row =
    Rows(partial_map(
        similar_at,
        (first(rows.columns), dimensions),
        val_fieldtypes(Row)
    ))

empty(column::Rows{OldRow}, ::Type{NewRow} = OldRow) where {OldRow, NewRow} =
    similar(column, NewRow)

maybe_setindex_widen_up_to(column::AbstractArray{Item}, item, an_index...) where {Item} =
    if isa(item, Item)
        @inbounds column[an_index...] = item
        column
    else
        setindex_widen_up_to(column, item, an_index...)
    end

setindex_widen_up_to_at((columns, an_index), (name, a_value)) =
    if haskey(columns, name)
        name, maybe_setindex_widen_up_to(columns[name], a_value, an_index...)
    else
        name, similar(value(first(columns)), Union{Missing, typeof(a_value)})
    end
function setindex_widen_up_to(rows::Rows, row, an_index...)
    columns = to_columns(rows)
    Rows(transform(columns, partial_map(
        setindex_widen_up_to_at,
        (columns, an_index),
        row
    )...))
end

maybe_push_widen(column::AbstractArray{Item}, item) where {Item} =
    if isa(item, Item)
        push!(column, item)
        column
    else
        push_widen(column, item)
    end
push_widen_at(columns, (name, a_value)) =
    if haskey(columns, name)
        name, maybe_push_widen(columns[name], a_value)
    else
        model = value(first(columns))
        name, similar(model, Union{Missing, typeof(a_value)}, length(model) + 1)
    end
function push_widen(rows::Rows, row)
    columns = to_columns(rows)
    Rows(transform(columns, partial_map(push_widen_at, columns, row)...))
end
view_at(an_index, name, column) = name, view(column, an_index...)
view(rows::Rows, an_index...) = Rows(partial_map(
    view_at, an_index, rows.names, rows.columns
))

"""
    make_columns(rows)

Collect into columns. Always eager, see [`to_columns`](@ref) for a lazy version.

```jldoctest make_columns
julia> using LightQuery

julia> rows = @name [(a = 1, b = 1.0), (a = 2, b = 2.0)];

julia> make_columns(rows)
((`a`, [1, 2]), (`b`, [1.0, 2.0]))

julia> empty!(rows);

julia> make_columns(rows)
((`a`, Int64[]), (`b`, Float64[]))
```
"""
make_columns(rows) = to_columns(_collect(
    Rows(@name (a = 1:1,)),
    rows,
    IteratorEltype(rows),
    IteratorSize(rows)
))
export make_columns
