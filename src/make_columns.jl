struct Rows{Row, Dimensions, Columns, Names} <: AbstractArray{Row, Dimensions}
    columns::Columns
    names::Names
end
Rows{Row, Dimension}(columns::Columns, the_names::Names) where {Row, Dimension, Columns, Names} =
    Rows{Row, Dimension, Columns, Names}(columns, the_names)

get_model(columns) = first(columns)
get_model(::Tuple{}) = 1:0

column_Value(::Name, ::Column) where {Name, Column} =
    Tuple{Name, eltype(Column)}

function Rows(named_columns)
    column_names = map_unrolled(key, named_columns)
    columns = map_unrolled(value, named_columns)
    Rows{
        Tuple{map_unrolled(column_Value, column_names, columns)...},
        ndims(get_model(columns))
    }(columns, column_names)
end

get_columns(rows::Rows) = map_unrolled(tuple, rows.names, rows.columns)

axes(rows::Rows, dimensions...) = axes(get_model(rows.columns), dimensions...)
size(rows::Rows, dimensions...) = size(get_model(rows.columns), dimensions...)

@propagate_inbounds column_getindex((columns, an_index), name) =
    name, if haskey(columns, name)
        name(columns)[an_index...]
    else
        missing
    end
@propagate_inbounds getindex(rows::Rows, an_index...) = partial_map(
    column_getindex,
    (get_columns(rows), an_index),
    rows.names
)

@propagate_inbounds column_setindex!((columns, an_index), (name, value)) =
    if haskey(columns, name)
        name(columns)[an_index...] = value
    else
        missing
    end
@propagate_inbounds setindex!(rows::Rows, row, an_index...) =
    partial_map(column_setindex!, (get_columns(rows), an_index), row)

column_push!(columns, (name, value)) =
    if haskey(columns, name)
        push!(name(columns), value)
    else
        missing
    end
push!(rows::Rows, row) = partial_map(column_push!, get_columns(rows), row)

val_fieldtypes(something) = ()
@pure val_fieldtypes(a_type::DataType) =
    if a_type.abstract || (a_type.name == Tuple.name && isvatuple(a_type))
        ()
    else
        map_unrolled(Val, (a_type.types...,))
    end

val_Value(::Val{Tuple{Name{name}, Value}}) where {name, Value} =
    Name{name}(), Val{Value}()
val_Value(type) = missing

val_Row(Row) = filter_unrolled(
    !ismissing,
    map_unrolled(val_Value, val_fieldtypes(Row))...
)

similar_val(model, ::Val{Value}, dimensions) where {Value} =
    similar(model, Value, dimensions)
similar_column((model, dimensions), (name, val_Value)) =
    name, similar_val(model, val_Value, dimensions)
similar(rows::Rows, ::Type{ARow}, dimensions::Dims) where {ARow} =
    Rows(partial_map(
        similar_column,
        (get_model(rows.columns), dimensions),
        val_Row(ARow)
    ))

empty(column::Rows{OldRow}, ::Type{NewRow} = OldRow) where {OldRow, NewRow} =
    similar(column, NewRow)

function widen_column(::HasLength, new_length, an_index, name, column::Array{Element}, item::Item) where {Element, Item <: Element}
    @inbounds column[an_index] = item
    name, column
end
widen_column(::HasLength, new_length, an_index, name, column::Array, item) =
    name, setindex_widen_up_to(column, item, an_index)

function widen_column(::SizeUnknown, new_length, an_index, name, column::Array{Element}, item::Item) where {Element, Item <: Element}
    push!(column, item)
    name, column
end
widen_column(::SizeUnknown, new_length, an_index, name, column::Array, item) =
    name, push_widen(column, item)

function widen_column(iterator_size, new_length, an_index, name, ::Missing, item::Item) where {Item}
    new_column = Array{Union{Missing, Item}}(missing, new_length)
    @inbounds new_column[an_index] = item
    name, new_column
end
widen_column(iterator_size, new_length, an_index, name, ::Missing, ::Missing) =
    name, Array{Missing}(missing, new_length)

widen_column(fixeds, variables) = widen_column(fixeds..., variables...)

get_new_length(::SizeUnknown, rows, an_index) = an_index
get_new_length(::HasLength, rows, an_index) = length(rows)

lone_column((name, column)) = name, column, missing
lone_value((name, value)) = name, missing, value
column_value((column_name, column), (value_name, value)) =
    column_name, column, value

function widen_named(iterator_size, rows, row, an_index = length(rows) + 1)
    named_columns = get_columns(rows)
    new_length = get_new_length(iterator_size, rows, an_index)
    column_names = map_unrolled(key, named_columns)
    value_names = map_unrolled(key, row)
    just_column_names = diff_unrolled(column_names, value_names)
    just_value_names = diff_unrolled(value_names, column_names)
    in_both_names = diff_unrolled(column_names, just_column_names)
    Rows(partial_map(
        widen_column,
        (iterator_size, get_new_length(iterator_size, rows, an_index), an_index),
        (
            map_unrolled(lone_column, just_column_names(named_columns))...,
            map_unrolled(
                column_value,
                in_both_names(named_columns),
                in_both_names(row)
            )...,
            map_unrolled(lone_value, just_value_names(row))...
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
make_columns(rows) = get_columns(_collect(
    Rows(()),
    rows,
    IteratorEltype(rows),
    IteratorSize(rows)
))

export make_columns
