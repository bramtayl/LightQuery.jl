struct Rows{Row,Dimensions,Columns,Names} <: AbstractArray{Row,Dimensions}
    columns::Columns
    names::Names
    @propagate_inbounds function Rows{Row,Dimension,Columns,Names}(
        columns,
        the_names,
    ) where {Row,Dimension,Columns,Names}
        @boundscheck if !same_axes(columns...)
            throw(DimensionMismatch("All columns passed to `Rows` must have the same axes"))
        end
        new{Row,Dimension,Columns,Names}(columns, the_names)
    end
end
export Rows

function same_axes(first_column, rest...)
    my_all(
        partial_map(function (reference_axes, item)
            axes(item) == reference_axes
        end, axes(first_column), rest)
    )
end
function same_axes()
    true
end
@propagate_inbounds function Rows{Row,Dimension}(
    columns::Columns,
    the_names::Names,
) where {Row,Dimension,Columns,Names}
    Rows{Row,Dimension,Columns,Names}(columns, the_names)
end
@propagate_inbounds function Rows(columns, the_names)
    Rows{
        NamedTuple{map(unname, the_names),Tuple{map(eltype, columns)...}},
        ndims(get_model(columns)),
    }(
        columns,
        the_names,
    )
end

@propagate_inbounds function Rows(named_columns)
    Rows(map(value, named_columns), map(key, named_columns))
end

"""
    Rows(named_columns)

Iterator over `rows` of a table. Always lazy. Use [`Peek`](@ref) to view.

```jldoctest Rows
julia> using LightQuery


julia> using Test: @inferred


julia> lazy = @inferred Rows(a = [1, 2], b = [1.0, 2.0])
2-element Rows{NamedTuple{(:a, :b),Tuple{Int64,Float64}},1,Tuple{Array{Int64,1},Array{Float64,1}},Tuple{Name{:a},Name{:b}}}:
 (a = 1, b = 1.0)
 (a = 2, b = 2.0)

julia> @inferred collect(lazy)
2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Float64}},1}:
 (a = 1, b = 1.0)
 (a = 2, b = 2.0)

julia> @inferred Rows(a = [1, 2])
2-element Rows{NamedTuple{(:a,),Tuple{Int64}},1,Tuple{Array{Int64,1}},Tuple{Name{:a}}}:
 (a = 1,)
 (a = 2,)
```

All arguments to Rows must have the same axes. Use `@inbounds` to override the
check.

```jldoctest Rows
julia> result = Rows(a = 1:2, b = 1:3)
ERROR: DimensionMismatch("All columns passed to `Rows` must have the same axes")
[...]
```
"""
@propagate_inbounds function Rows(; columns...)
    Rows(named_tuple(columns.data))
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

function to_columns(rows::Rows)
    map(tuple, rows.names, rows.columns)
end

function axes(rows::Rows, dimensions...)
    axes(parent(rows), dimensions...)
end
function size(rows::Rows, dimensions...)
    size(parent(rows), dimensions...)
end

@propagate_inbounds function getindex(rows::Rows, an_index::Int...)
    NamedTuple(partial_map(
        (@propagate_inbounds function ((columns, an_index), name)
            name, name(columns)[an_index...]
        end),
        (to_columns(rows), an_index),
        rows.names,
    ))
end

@propagate_inbounds function setindex!(rows::Rows, row::MyNamedTuple, an_index::Int...)
    partial_for_each(
        (@propagate_inbounds function ((columns, an_index), (name, value))
            name(columns)[an_index...] = value
            nothing
        end),
        (to_columns(rows), an_index),
        row,
    )
end
@propagate_inbounds function setindex!(rows::Rows, row, an_index::Int...)
    setindex!(rows, named_tuple(row), an_index...)
end

function push!(rows::Rows, row::MyNamedTuple)
    partial_for_each(function (columns, (name, value))
        push!(name(columns), value)
        nothing
    end, to_columns(rows), row)
end
function push!(rows::Rows, row)
    push!(rows, named_tuple(row))
end

function val_fieldtypes(something)
    ()
end
@pure function val_fieldtypes(a_type::DataType)
    if a_type.abstract || (a_type.name == Tuple.name && isvatuple(a_type))
        ()
    else
        map(Val, (a_type.types...,))
    end
end

function decompose_row_type(::Type{<:NamedTuple{Names,ATuple}}) where {Names,ATuple}
    map(tuple, to_Names(Names), val_fieldtypes(ATuple))
end
function decompose_row_type(uninferred)
    ()
end

function similar(rows::Rows, ::Type{ARow}, dimensions::Dims) where {ARow}
    @inbounds Rows(partial_map(
        function (
            (model, dimensions),
            (name, val_Value)::Tuple{<:Any,Val{Value}},
        ) where {Value}
            name, similar(model, Value, dimensions)
        end,
        (parent(rows), dimensions),
        decompose_row_type(ARow),
    ))
end

function empty(column::Rows{OldRow}, ::Type{NewRow} = OldRow) where {OldRow,NewRow}
    similar(column, NewRow)
end

function widen_column(
    ::HasLength,
    new_length,
    an_index,
    name,
    column::AbstractArray{Element},
    item::Item,
) where {Element,Item<:Element}
    @inbounds column[an_index] = item
    name, column
end
function widen_column(::HasLength, new_length, an_index, name, column::AbstractArray, item)
    name, setindex_widen_up_to(column, item, an_index)
end
function widen_column(
    ::SizeUnknown,
    new_length,
    an_index,
    name,
    column::AbstractArray{Element},
    item::Item,
) where {Element,Item<:Element}
    push!(column, item)
    name, column
end
function widen_column(
    ::SizeUnknown,
    new_length,
    an_index,
    name,
    column::AbstractArray,
    item,
)
    name, push_widen(column, item)
end
function widen_column(
    iterator_size,
    new_length,
    an_index,
    name,
    ::Missing,
    item::Item,
) where {Item}
    new_column = Array{Union{Missing,Item}}(missing, new_length)
    @inbounds new_column[an_index] = item
    name, new_column
end
function widen_column(iterator_size, new_length, an_index, name, ::Missing, ::Missing)
    name, Array{Missing}(missing, new_length)
end

function get_new_length(::SizeUnknown, rows, an_index)
    an_index
end
function get_new_length(::HasLength, rows, an_index)
    length(LinearIndices(rows))
end

function widen_named(iterator_size, rows, row, an_index = length(rows) + 1)
    named_columns = to_columns(rows)
    column_names = map(key, named_columns)
    value_names = map(key, row)
    just_column_names = my_setdiff(column_names, value_names)
    in_both_names = my_setdiff(column_names, just_column_names)
    @inbounds Rows(partial_map(
        function (fixeds, variables)
            widen_column(fixeds..., variables...)
        end,
        (iterator_size, get_new_length(iterator_size, rows, an_index), an_index),
        (
            map(function ((name, column),)
                name, column, missing
            end, just_column_names(named_columns))...,
            map(
                function ((column_name, column), (value_name, value))
                    column_name, column, value
                end,
                in_both_names(named_columns),
                in_both_names(row),
            )...,
            map(function ((name, value),)
                name, missing, value
            end, my_setdiff(value_names, column_names)(row))...,
        ),
    ))
end

function push_widen(rows::Rows, row)
    widen_named(SizeUnknown(), rows, named_tuple(row))
end
function setindex_widen_up_to(rows::Rows, row, an_index)
    widen_named(HasLength(), rows, named_tuple(row), an_index)
end

"""
    make_columns(rows)

Collect into columns.

```jldoctest make_columns
julia> using LightQuery


julia> using Test: @inferred


julia> stable(x) = (a = x, b = x + 0.0, c = x, d = x + 0.0, e = x, f = x + 0.0);


julia> @inferred make_columns(over(1:4, stable))
(a = [1, 2, 3, 4], b = [1.0, 2.0, 3.0, 4.0], c = [1, 2, 3, 4], d = [1.0, 2.0, 3.0, 4.0], e = [1, 2, 3, 4], f = [1.0, 2.0, 3.0, 4.0])

julia> unstable(x) =
           if x <= 2
               (a = missing, b = string(x), d = string(x))
           else
               (a = x, b = missing, c = x)
           end;


julia> make_columns(over(1:4, unstable))
(d = Union{Missing, String}["1", "2", missing, missing], a = Union{Missing, Int64}[missing, missing, 3, 4], b = Union{Missing, String}["1", "2", missing, missing], c = Union{Missing, Int64}[missing, missing, 3, 4])

julia> make_columns(when(over(1:4, unstable), row -> true))
(d = Union{Missing, String}["1", "2", missing, missing], a = Union{Missing, Int64}[missing, missing, 3, 4], b = Union{Missing, String}["1", "2", missing, missing], c = Union{Missing, Int64}[missing, missing, 3, 4])
```
"""
function make_columns(rows)
    NamedTuple(to_columns(_collect(
        Rows(),
        rows,
        EltypeUnknown(),
        IteratorSize(rows),
    )))
end

export make_columns
