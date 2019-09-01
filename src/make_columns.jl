struct Rows{Row, Dimensions, Columns, Names} <: AbstractArray{Row, Dimensions}
    columns::Columns
    names::Names
end
function Rows{Row, Dimension}(columns::Columns, the_names::Names) where {Row, Dimension, Columns, Names}
    Rows{Row, Dimension, Columns, Names}(columns, the_names)
end

function get_model(columns)
    first(columns)
end
function get_model(::Tuple{})
    1:0
end

function parent(rows::Rows)
    get_model(rows.columns)
end

function name_eltype(::Name, ::Column) where {Name, Column}
    Tuple{Name, eltype(Column)}
end

function Rows(columns, the_names)
    Rows{
        Tuple{map_unrolled(name_eltype, the_names, columns)...},
        ndims(get_model(columns))
    }(columns, the_names)
end

export Rows

"""
    Rows(named_columns)

Iterator over `rows` of a table. Always lazy. Use [`Peek`](@ref) to view. Note
that `Rows` offers more performance, but has stricter requirements than
[`to_rows`](@ref). `Rows` requires that the iteration state for the first column
can generate an index for all of the colums.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> lazy = @name @inferred Rows((a = [1, 2], b = [1.0, 2.0]))
2-element Rows{Tuple{Tuple{Name{:a},Int64},Tuple{Name{:b},Float64}},1,Tuple{Array{Int64,1},Array{Float64,1}},Tuple{Name{:a},Name{:b}}}:
 ((`a`, 1), (`b`, 1.0))
 ((`a`, 2), (`b`, 2.0))

julia> @inferred collect(lazy)
2-element Array{Tuple{Tuple{Name{:a},Int64},Tuple{Name{:b},Float64}},1}:
 ((`a`, 1), (`b`, 1.0))
 ((`a`, 2), (`b`, 2.0))
```
"""
function Rows(named_columns)
    Rows(map_unrolled(value, named_columns), map_unrolled(key, named_columns))
end

function to_columns(rows::Rows)
    map_unrolled(tuple, rows.names, rows.columns)
end

function axes(rows::Rows, dimensions...)
    axes(parent(rows), dimensions...)
end
function size(rows::Rows, dimensions...)
    size(parent(rows), dimensions...)
end

@propagate_inbounds function column_getindex((columns, an_index), name)
    name, if haskey(columns, name)
        name(columns)[an_index...]
    else
        missing
    end
end
@propagate_inbounds function getindex(rows::Rows, an_index::Int...)
    partial_map(
        column_getindex,
        (to_columns(rows), an_index),
        rows.names
    )
end

@propagate_inbounds function column_setindex!((columns, an_index), (name, value))
    if haskey(columns, name)
        name(columns)[an_index...] = value
    end
    nothing
end
@propagate_inbounds function setindex!(rows::Rows, row, an_index::Int...)
    partial_map(column_setindex!, (to_columns(rows), an_index), row)
    nothing
end

function column_push!(columns, (name, value))
    if haskey(columns, name)
        push!(name(columns), value)
    end
    nothing
end
function push!(rows::Rows, row)
    partial_map(column_push!, to_columns(rows), row)
    nothing
end

function val_fieldtypes(something)
    ()
end
@pure function val_fieldtypes(a_type::DataType)
    if a_type.abstract || (a_type.name == Tuple.name && isvatuple(a_type))
        ()
    else
        map_unrolled(Val, (a_type.types...,))
    end
end

function decompose_named_type(::Val{Tuple{Name{name}, Value}}) where {name, Value}
    Name{name}(), Val{Value}()
end
function decompose_named_type(type)
    missing
end

function decompose_row_type(Row)
    filter_unrolled(
        !ismissing,
        map_unrolled(decompose_named_type, val_fieldtypes(Row))...
    )
end

function similar_val(model, ::Val{Value}, dimensions) where {Value}
    similar(model, Value, dimensions)
end
function similar_column((model, dimensions), (name, val_Value))
    name, similar_val(model, val_Value, dimensions)
end
function similar(rows::Rows, ::Type{ARow}, dimensions::Dims) where {ARow}
    Rows(partial_map(
        similar_column,
        (parent(rows), dimensions),
        decompose_row_type(ARow)
    ))
end

function empty(column::Rows{OldRow}, ::Type{NewRow} = OldRow) where {OldRow, NewRow}
    similar(column, NewRow)
end

function widen_column(::HasLength, new_length, an_index, name, column::AbstractArray{Element}, item::Item) where {Element, Item <: Element}
    @inbounds column[an_index] = item
    name, column
end
function widen_column(::HasLength, new_length, an_index, name, column::AbstractArray, item)
    name, setindex_widen_up_to(column, item, an_index)
end
function widen_column(::SizeUnknown, new_length, an_index, name, column::AbstractArray{Element}, item::Item) where {Element, Item <: Element}
    push!(column, item)
    name, column
end
function widen_column(::SizeUnknown, new_length, an_index, name, column::AbstractArray, item)
    name, push_widen(column, item)
end
function widen_column(iterator_size, new_length, an_index, name, ::Missing, item::Item) where {Item}
    new_column = Array{Union{Missing, Item}}(missing, new_length)
    @inbounds new_column[an_index] = item
    name, new_column
end
function widen_column(iterator_size, new_length, an_index, name, ::Missing, ::Missing)
    name, Array{Missing}(missing, new_length)
end
function widen_column_clumped(fixeds, variables)
    widen_column(fixeds..., variables...)
end

function get_new_length(::SizeUnknown, rows, an_index)
    an_index
end
function get_new_length(::HasLength, rows, an_index)
    length(LinearIndices(rows))
end

function lone_column((name, column))
    name, column, missing
end
function lone_value((name, value))
    name, missing, value
end
function column_value((column_name, column), (value_name, value))
    column_name, column, value
end

function widen_named(iterator_size, rows, row, an_index = length(rows) + 1)
    named_columns = to_columns(rows)
    column_names = map_unrolled(key, named_columns)
    value_names = map_unrolled(key, row)
    just_column_names = diff_unrolled(column_names, value_names)
    in_both_names = diff_unrolled(column_names, just_column_names)
    Rows(partial_map(
        widen_column_clumped,
        (
            iterator_size,
            get_new_length(iterator_size, rows, an_index),
            an_index
        ),
        (
            map_unrolled(lone_column, just_column_names(named_columns))...,
            map_unrolled(
                column_value,
                in_both_names(named_columns),
                in_both_names(row)
            )...,
            map_unrolled(
                lone_value,
                diff_unrolled(value_names, column_names)(row)
            )...
        )
    ))
end

function push_widen(rows::Rows, row)
    widen_named(SizeUnknown(), rows, row)
end
function setindex_widen_up_to(rows::Rows, row, an_index)
    widen_named(HasLength(), rows, row, an_index)
end

"""
    make_columns(rows)

Collect into columns. Always eager; see [`to_columns`](@ref) for a lazy, but
less powerful, version.

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
function make_columns(rows)
    to_columns(_collect(
        Rows(()),
        rows,
        IteratorEltype(rows),
        IteratorSize(rows)
    ))
end

export make_columns

function get_columns(rows::Rows)
    rows.columns
end

function view_backwards(indexes, column)
    view(column, indexes)
end
@propagate_inbounds function view(rows::Rows, indexes::IndexRange)
    Rows(
        partial_map(view_backwards, indexes, rows.columns),
        rows.names
    )
end
