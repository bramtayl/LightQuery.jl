struct Rows{Row, Dimensions, Columns, Names} <: AbstractArray{Row, Dimensions}
    columns::Columns
    names::Names
end

row_type_at(::Name, column) = Tuple{Name, eltype(column)}
row_type(names, columns) =
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

axes(rows::Rows, dimensions...) =
    axes(first(rows.columns), dimensions...)
size(rows::Rows, dimensions...) =
    size(first(rows.columns), dimensions...)

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

push!(rows::Rows, row) = partial_map((columns, (name, value)) ->
    if has_name(columns, name)
        push!(get_name(columns, name), value)
        nothing
    end, to_columns(rows), row)

similar_named((model, dimensions), ::Val{Tuple{Name{name}, Value}}) where {name, Value} =
    Name{name}(), similar(model, Value, dimensions)

similar(rows::Rows{Tuple{}}, ::Type{Row}, dimensions::Dims) where Row =
    Rows(partial_map(
        similar_named,
        (1:1, 0),
        val_fieldtypes_or_empty(Row)
    ))
similar(rows::Rows, ::Type{Row}, dimensions::Dims) where Row =
    Rows(partial_map(
        similar_named,
        (first(rows.columns), dimensions),
        val_fieldtypes_or_empty(Row)
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
    if has_name(columns, name)
        name, maybe_setindex_widen_up_to(get_name(columns, name), a_value, an_index...)
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
    if has_name(columns, name)
        name, maybe_push_widen(get_name(columns, name), a_value)
    else
        model = value(first(columns))
        name, similar(model, Union{Missing, typeof(a_value)}, length(model) + 1)
    end
function push_widen(rows::Rows, row)
    columns = to_columns(rows)
    Rows(transform(columns, partial_map(push_widen_at, columns, row)...))
end

view(rows::Rows, an_index...) = Rows(partial_map(
    (an_index, name, column) -> (name, view(column, an_index...)),
    an_index, rows.names,
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
    Rows(@name (a = 1:1,)),
    rows,
    IteratorEltype(rows),
    IteratorSize(rows)
))
export make_columns

@static if VERSION < v"1.1"
    # backport #30076 just for Rows
    import Base: collect_to!, grow_to!
    using Base: promote_typejoin

    function collect_to!(dest::Rows{T}, itr, offs, st) where T
        # collect to dest array, checking the type of each result. if a result does not
        # match, widen the result type and re-dispatch.
        i = offs
        while true
            y = iterate(itr, st)
            y === nothing && break
            el, st = y
            if el isa T || typeof(el) === T
                @inbounds dest[i] = el::T
                i += 1
            else
                new = setindex_widen_up_to(dest, el, i)
                return collect_to!(new, itr, i+1, st)
            end
        end
        return dest
    end

    @inline function setindex_widen_up_to(dest::AbstractArray{T}, el, i) where T
        new = similar(dest, promote_typejoin(T, typeof(el)))
        copyto!(new, firstindex(new), dest, firstindex(dest), i-1)
        @inbounds new[i] = el
        return new
    end

    function grow_to!(dest::Rows, itr, st)
        T = eltype(dest)
        y = iterate(itr, st)
        while y !== nothing
            el, st = y
            if el isa T || typeof(el) === T
                push!(dest, el::T)
            else
                new = push_widen(dest, el)
                return grow_to!(new, itr, st)
            end
            y = iterate(itr, st)
        end
        return dest
    end

    @inline function push_widen(dest, el)
        new = sizehint!(empty(dest, promote_typejoin(eltype(dest), typeof(el))), length(dest))
        if new isa AbstractSet
            # TODO: merge back these two branches when copy! is re-enabled for sets/vectors
            union!(new, dest)
        else
            append!(new, dest)
        end
        push!(new, el)
        return new
    end

end
