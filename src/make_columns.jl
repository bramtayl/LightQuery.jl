struct Rows{Row, Dimensions, Columns, Names} <: AbstractArray{Row, Dimensions}
    columns::Columns
    names::Names
end

model(columns::Some{Any}) = first(columns)
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

lone_first((name, item)) = name, item, missing
lone_second((name, item)) = name, missing, item
found_match((name1, item1)::Tuple{Name{name}, Any}, (name2, item2)::Tuple{Name{name}, Any}) where {name} =
    name1, item1, item2

function full_merge(row1, row2)
    lone_row1 = diff_names_unrolled(row1, row2)
    lone_row2 = diff_names_unrolled(row2, row1)
    matching_row1 = diff_names_unrolled(row1, lone_row1)
    map(lone_first, lone_row1)...,
    map(
        found_match,
        matching_row1,
        diff_names_unrolled(row2, lone_row2)[map(key, matching_row1)]
    )...,
    map(lone_second, lone_row2)...
end

function widen_named(iterator_size, rows, row, an_index = length(rows) + 1)
    named_columns = to_columns(rows)
    the_length = model_length(iterator_size, rows, an_index)
    Rows(partial_map(
        widen_at,
        (iterator_size, the_length, an_index),
        full_merge(named_columns, row)
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
                (a = missing, b = x + 0.0, d = x + 0.0)
            else
                (a = x, b = missing, c = x)
            end;

julia> make_columns(over(1:4, unstable))
((`d`, Union{Missing, Float64}[1.0, 2.0, missing, missing]), (`a`, Union{Missing, Int64}[missing, missing, 3, 4]), (`b`, Union{Missing, Float64}[1.0, 2.0, missing, missing]), (`c`, Union{Missing, Int64}[missing, missing, 3, 4]))

julia> make_columns(when(over(1:4, unstable), row -> true))
((`d`, Union{Missing, Float64}[1.0, 2.0, missing, missing]), (`a`, Union{Missing, Int64}[missing, missing, 3, 4]), (`b`, Union{Missing, Float64}[1.0, 2.0, missing, missing]), (`c`, Union{Missing, Int64}[missing, missing, 3, 4]))

```
"""
make_columns(rows) = to_columns(_collect(
    Rows(()),
    rows,
    IteratorEltype(rows),
    IteratorSize(rows)
))

export make_columns
