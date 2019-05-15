struct Rows{Row, Dimensions, Columns, Names} <: AbstractArray{Row, Dimensions}
    columns::Columns
    names::Names
end

model(them) = first(them)
model(::Tuple{}) = 1:0

row_type_at(::Name, column) where {Name} = Tuple{Name, eltype(column)}
function Rows(named_columns)
    some_names = map(key, named_columns)
    columns = map(value, named_columns)
    Rows{
        Tuple{map(row_type_at, some_names, columns)...},
        ndims(model(columns)),
        typeof(columns),
        typeof(some_names)
    }(columns, some_names)
end

to_columns(rows::Rows) = map(tuple, rows.names, rows.columns)

axes(rows::Rows, dimensions...) = axes(model(rows.columns), dimensions...)
size(rows::Rows, dimensions...) = size(model(rows.columns), dimensions...)

@propagate_inbounds getindex_at((columns, an_index), name) =
    name, if has_name(columns, name)
        get_name(columns, name)[an_index...]
    else
        missing
    end
@propagate_inbounds getindex(rows::Rows, an_index...) =
    partial_map(getindex_at, (to_columns(rows), an_index), rows.names)

@propagate_inbounds setindex_at!((columns, an_index), (name, value)) =
    if has_name(columns, name)
        get_name(columns, name)[an_index...] = value
        nothing
    end
@propagate_inbounds setindex!(rows::Rows, row, an_index...) =
    partial_map(setindex_at!, (to_columns(rows), an_index), row)

push_at!(columns, (name, value)) = if has_name(columns, name)
    push!(get_name(columns, name), value)
    nothing
end
push!(rows::Rows, row) = partial_map(push_at!, to_columns(rows), row)

decompose_named_type(::Val{Tuple{Name{name}, Value}}) where {name, Value} =
    Name{name}(), Val{Value}()
decompose_named_type(type) = missing

decompose_named_tuple_type(type) = filter_unrolled(
    !ismissing,
    map(decompose_named_type, val_fieldtypes_or_empty(type))
)

similar_val(model, ::Val{AType}, dimensions) where {AType} =
    similar(model, AType, dimensions)
similar_named((model, dimensions), (name, val_type)) =
    name, similar_val(model, val_type, dimensions)
similar(rows::Rows, ::Type{Row}, dimensions::Dims) where Row =
    Rows(partial_map(
        similar_named,
        (model(rows.columns), dimensions),
        decompose_named_tuple_type(Row)
    ))

empty(column::Rows{OldRow}, ::Type{NewRow} = OldRow) where {OldRow, NewRow} =
    similar(column, NewRow)

setindex_widen_up_to_at((columns, an_index), (name, item)) =
    if has_name(columns, name)
        column = get_name(columns, name)
        name, if isa(item, eltype(column))
            @inbounds column[an_index...] = item
            column
        else
            setindex_widen_up_to(column, item, an_index...)
        end
    else
        name, similar(value(model(columns)), Union{Missing, typeof(item)})
    end
function setindex_widen_up_to(rows::Rows, row, an_index...)
    columns = to_columns(rows)
    Rows(transform(columns, partial_map(
        setindex_widen_up_to_at,
        (columns, an_index),
        row
    )...))
end

push_widen_at(columns, (name, item)) =
    if has_name(columns, name)
        column = get_name(columns, name)
        name, if isa(item, eltype(column))
            push!(column, item)
            column
        else
            push_widen(column, item)
        end
    else
        the_model = value(model(columns))
        name, similar(the_model, Union{Missing, typeof(item)}, length(the_model) + 1)
    end
function push_widen(rows::Rows, row)
    columns = to_columns(rows)
    Rows(transform(columns, partial_map(push_widen_at, columns, row)...))
end

view_at(an_index, name, column) = (name, view(column, an_index...))
view(rows::Rows, an_index...) = Rows(partial_map(
    view_at,
    an_index,
    rows.names,
    rows.columns
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
    Rows(()),
    rows,
    IteratorEltype(rows),
    IteratorSize(rows)
))
export make_columns
