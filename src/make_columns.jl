struct Rows{Row, Dimensions, Columns, Names} <: AbstractArray{Row, Dimensions}
    columns::Columns
    names::Names
end

model(columns) = first(columns)
model(::Tuple{}) = 1:0

row_type_at(::Name, ::Column) where {Name, Column} = Tuple{Name, eltype(Column)}
Rows{Row, Dimension}(columns::Columns, names::Names) where {Row, Dimension, Columns, Names} =
    Rows{Row, Dimension, Columns, Names}(columns, names)
function Rows(named_columns)
    some_names = map_unrolled(key, named_columns)
    columns = map_unrolled(value, named_columns)
    Rows{
        Tuple{map_unrolled(row_type_at, some_names, columns)...},
        ndims(model(columns))
    }(columns, some_names)
end

to_columns(rows::Rows) = map_unrolled(tuple, rows.names, rows.columns)

axes(rows::Rows, dimensions...) = axes(model(rows.columns), dimensions...)
size(rows::Rows, dimensions...) = size(model(rows.columns), dimensions...)

@propagate_inbounds getindex_at((columns, an_index), name) =
    name, if haskey(columns, name)
        columns[name][an_index...]
    else
        missing
    end
@propagate_inbounds getindex(rows::Rows, an_index...) =
    partial_map(getindex_at, (to_columns(rows), an_index), rows.names)

@propagate_inbounds function setindex_at!((columns, an_index), (name, value))
    if haskey(columns, name)
        columns[name][an_index...] = value
    end
    nothing
end
@propagate_inbounds setindex!(rows::Rows, row, an_index...) =
    partial_map(setindex_at!, (to_columns(rows), an_index), row)

function push_at!(columns, (name, value))
    if haskey(columns, name)
        push!(columns[name], value)
    end
    nothing
end
push!(rows::Rows, row) = partial_map(push_at!, to_columns(rows), row)

val_fieldtypes_or_empty(something) = ()
@pure val_fieldtypes_or_empty(a_type::DataType) =
    if a_type.abstract || (a_type.name == Tuple.name && isvatuple(a_type))
        ()
    else
        map_unrolled(Val, (a_type.types...,))
    end

decompose_named_type(::Val{Tuple{Name{name}, type}}) where {name, type} =
    Name{name}(), Val{type}()
decompose_named_type(type) = missing

decompose_named_tuple_type(type) = filter_unrolled(
    !ismissing,
    map_unrolled(decompose_named_type, val_fieldtypes_or_empty(type))...
)

similar_val_type(the_model, ::Val{type}, dimensions) where {type} =
    similar(the_model, type, dimensions)
similar_named((the_model, dimensions), (name, val_type)) =
    name, similar_val_type(the_model, val_type, dimensions)
similar(rows::Rows, ::Type{ARow}, dimensions::Dims) where {ARow} =
    Rows(partial_map(
        similar_named,
        (model(rows.columns), dimensions),
        decompose_named_tuple_type(ARow)
    ))

empty(column::Rows{OldRow}, ::Type{NewRow} = OldRow) where {OldRow, NewRow} =
    similar(column, NewRow)

function widen_at(::HasLength, the_length, an_index, name, column::Array{Element}, item::Item) where {Element, Item <: Element}
    @inbounds column[an_index] = item
    name, column
end
widen_at(::HasLength, the_length, an_index, name, column::Array, item) =
    name, setindex_widen_up_to(column, item, an_index)

function widen_at(::SizeUnknown, the_length, an_index, name, column::Array{Element}, item::Item) where {Element, Item <: Element}
    push!(column, item)
    name, column
end
widen_at(::SizeUnknown, the_length, an_index, name, column::Array, item) =
    name, push_widen(column, item)

function widen_at(iteratorsize, the_length, an_index, name, ::Missing, item::Item) where {Item}
    new_column = Array{Union{Missing, Item}}(missing, the_length)
    @inbounds new_column[an_index] = item
    name, new_column
end
widen_at(iteratorsize, the_length, an_index, name, ::Missing, ::Missing) =
    name, Array{Missing}(missing, the_length)

widen_at(fixeds, variables) = widen_at(fixeds..., variables...)

model_length(::SizeUnknown, rows, an_index) = an_index
model_length(::HasLength, rows, an_index) = length(rows)

lone_column((name, column)) = name, column, missing
lone_row((name, row)) = name, missing, row
row_column_match((column_name, column), (row_name, row)) =
    column_name, column, row

function widen_named(iterator_size, rows, row, an_index = length(rows) + 1)
    named_columns = to_columns(rows)
    the_length = model_length(iterator_size, rows, an_index)
    column_names = map_unrolled(key, named_columns)
    row_names = map_unrolled(key, row)
    just_column_names = diff_unrolled(column_names, row_names)
    just_row_names = diff_unrolled(row_names, column_names)
    in_both_names = diff_unrolled(column_names, just_column_names)
    Rows(partial_map(
        widen_at,
        (iterator_size, model_length(iterator_size, rows, an_index), an_index),
        (
            map_unrolled(lone_column, named_columns[just_column_names])...,
            map_unrolled(
                row_column_match,
                named_columns[in_both_names],
                row[in_both_names]
            )...,
            map_unrolled(lone_row, row[just_row_names])...
        )
    ))
end

push_widen(rows::Rows, row) = widen_named(SizeUnknown(), rows, row)
setindex_widen_up_to(rows::Rows, row, an_index) =
    widen_named(HasLength(), rows, row, an_index)

"""
    make_columns(rows)

Collect into columns. Always eager, see [`to_columns`](@ref) for a lazy version.

```jldoctest make_columns
julia> using LightQuery

julia> using Test: @inferred

julia> stable(x) = @name (a = x, b = x + 0.0, c = x, d = x + 0.0, e = x, f = x + 0.0);

julia> @inferred make_columns(over(1:4, stable))
((`a`, [1, 2, 3, 4]), (`b`, [1.0, 2.0, 3.0, 4.0]), (`c`, [1, 2, 3, 4]), (`d`, [1.0, 2.0, 3.0, 4.0]), (`e`, [1, 2, 3, 4]), (`f`, [1.0, 2.0, 3.0, 4.0]))

julia> unstable(x) =
            @name if x <= 2
                (a = missing, b = string(x), d = string(x))
            else
                (a = x, b = missing, c = x)
            end;

julia> make_columns(over(1:4, unstable))
((`d`, Union{Missing, String}["1", "2", missing, missing]), (`a`, Union{Missing, Int64}[missing, missing, 3, 4]), (`b`, Union{Missing, String}["1", "2", missing, missing]), (`c`, Union{Missing, Int64}[missing, missing, 3, 4]))

julia> make_columns(when(over(1:4, unstable), row -> true))
((`d`, Union{Missing, String}["1", "2", missing, missing]), (`a`, Union{Missing, Int64}[missing, missing, 3, 4]), (`b`, Union{Missing, String}["1", "2", missing, missing]), (`c`, Union{Missing, Int64}[missing, missing, 3, 4]))
```
"""
make_columns(rows) = to_columns(_collect(
    Rows(()),
    rows,
    IteratorEltype(rows),
    IteratorSize(rows)
))

export make_columns
