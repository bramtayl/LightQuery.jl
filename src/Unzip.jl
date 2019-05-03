struct Rows{Row, Dimensions, Columns} <: AbstractArray{Row, Dimensions}
    columns::Columns
end
function Rows(model, rest...)
    columns = (model, rest...)
    Rows{
        Tuple{map(eltype, columns)...},
        ndims(model),
        typeof(columns)
    }(columns)
end
IteratorEltype(::Type{Rows{Row, Dimensions, Columns}}) where {Row, Dimensions, Columns} =
    _zip_iterator_eltype(Columns)
IteratorSize(::Type{Rows{Row, Dimensions, Columns}}) where {Row, Dimensions, Columns} =
    _zip_iterator_size(Columns)
axes(rows::Rows, dimensions...) =
	axes(rows.columns[1], dimensions...)
size(rows::Rows, dimensions...) =
	size(rows.columns[1], dimensions...)
@inline function getindex(rows::Rows, index...)
    @inline getindex_at(column) = column[index...]
    map(getindex_at, rows.columns)
end
@inline function setindex!(rows::Rows, row, index...)
    @inline setindex_at!(column, value) = column[index...] = value
    map(setindex_at!, rows.columns, row)
end
push!(rows::Rows, row) = map(push!, rows.columns, row)
function similar(rows::Rows, ::Type, dimensions::Dims)
	@inline similar_at(index) = Array{Any}(undef, dimensions...)
	zip(ntuple(similar_at, Val{length(rows.columns)}())...)
end
function similar(rows::Rows, ::Type{Row}, dimensions::Dims) where {Row <: Tuple}
	@inline similar_at(index) =
		Array{fieldtype(Row, index)}(undef, dimensions...)
	zip(ntuple(similar_at, Val{length(rows.columns)}())...)
end
empty(column::Rows{OldRow}, ::Type{NewRow} = OldRow) where {OldRow, NewRow} =
    similar(column, NewRow)
maybe_setindex_widen_up_to(column::AbstractArray{Item}, item, index) where {Item} =
    if isa(item, Item)
        @inbounds column[index] = item
        column
    else
        setindex_widen_up_to(column, item, index)
    end
setindex_widen_up_to(rows::Rows, row, index) =
	zip(map(
		(column, item) -> maybe_setindex_widen_up_to(column, item, index),
		rows.columns,
		row
	)...)
maybe_push_widen(column::AbstractArray{Item}, item) where {Item} =
    if isa(item, Item)
        push!(column, item)
        column
    else
        push_widen(column, item)
    end
push_widen(rows::Rows, row) =
    zip(map(maybe_push_widen, rows.columns, row)...)
view(rows::Rows, index...) =
    zip(map(column -> view(column, index...), rows.columns)...)

@generated type_length(::Val{Row}) where {Row} = Val{fieldcount(Row)}()

empty_number_of_columns(rows, ::HasEltype) = type_length(Val{eltype(rows)}())
empty_number_of_columns(rows, ::EltypeUnknown) =
	type_length(Val{@default_eltype(rows)}())

get_number_of_columns(rows) =
	if isempty(rows)
		empty_number_of_columns(rows, IteratorEltype(rows))
	else
		Val{length(first(rows))}()
	end

"""
    unzip(rows, number_of_columns = number_of_columns(rows))

Unzip an iterator `rows` which returns tuples of length `number_of_columns`.

```jldoctest
julia> using LightQuery

julia> unzip([(1, 1.0), (2, 2.0)])
([1, 2], [1.0, 2.0])
```
"""
unzip(rows, number_of_columns = get_number_of_columns(rows)) = _collect(
    zip(ntuple(x -> 1:1, number_of_columns)...),
    rows,
    IteratorEltype(rows),
    IteratorSize(rows)
).columns
export unzip

# piracy
zip(model::AbstractArray, rest::AbstractArray...) = Rows(model, rest...)
