struct ZippedArrays{ItemTypes, Dimensions, Arrays} <: AbstractArray{ItemTypes, Dimensions}
    arrays::Arrays
end

@propagate_inbounds function ZippedArrays(model, rest...)
    foreach(
        (@propagate_inbounds check_axes(array) =
            @boundscheck if axes(array) != axes(model)
                throw(BoundsError("All arrays passed to zip must have the same size"))
            end),
        rest
    )
    arrays = (model, rest...)
    ZippedArrays{
        Tuple{eltype.(arrays)...},
        ndims(model),
        typeof(arrays)
    }(arrays)
end

@propagate_inbounds zip(model::AbstractArray, rest::AbstractArray...) =
    ZippedArrays(model, rest...)

IteratorEltype(::Type{ZippedArrays{Items, Dimensions, Arrays}}) where {Items, Dimensions, Arrays} =
    _zip_iterator_eltype(Arrays)

IteratorSize(::Type{ZippedArrays{Items, Dimensions, Arrays}}) where {Items, Dimensions, Arrays} =
    _zip_iterator_size(Arrays)

axes(arrays::ZippedArrays, args...) =
    axes(arrays.arrays[1], args...)
size(arrays::ZippedArrays, args...) =
    size(arrays.arrays[1], args...)

function sizehint!(arrays::ZippedArrays, new_size...)
    (array -> size_hint!(array, new_size...)).(arrays.arrays)
	arrays
end
@propagate_inbounds function getindex(arrays::ZippedArrays, index...)
    @propagate_inbounds inner_getindex(array) = array[index...]
    inner_getindex.(arrays.arrays)
end
@propagate_inbounds function setindex!(arrays::ZippedArrays, values, index...)
    @propagate_inbounds inner_setindex!(array, value) = array[index...] = value
    inner_setindex!.(arrays.arrays, values)
end
push!(arrays::ZippedArrays, values) = push!.(arrays.arrays, values)

function similar(arrays::ZippedArrays, ::Type{Items}, dimensions::Dims) where {Items <: Tuple}
	@inline inner_similar(index) =
        Array{fieldtype(Items, index)}(undef, dimensions...)
	@inbounds zip(ntuple(inner_similar, length(arrays.arrays))...)
end

empty(array::ZippedArrays{OldItems}, ::Type{NewItems} = OldItems) where {OldItems, NewItems} =
    similar(array, NewItems)

export unzip
"""
    unzip(it, n)

Unzip an iterator `it` which returns tuples of length `n`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> f(x) = (x, x + 0.0);

julia> test(x) = unzip(x, 2);

julia> test(over([1, missing], f))
(Union{Missing, Int64}[1, missing], Union{Missing, Float64}[1.0, missing])

julia> @inferred test(zip([1], [1.0]))
([1], [1.0])

julia> @inferred test([(1, 1.0)])
([1], [1.0])

julia> test(over(when([1, missing], x -> true), f))
(Union{Missing, Int64}[1, missing], Union{Missing, Float64}[1.0, missing])
```
"""
@inline unzip(it, n) = _collect(
    zip(ntuple(x -> 1:1, n)...),
    it,
    IteratorEltype(it),
    IteratorSize(it)
).arrays

maybe_setindex_widen_up_to(array::AbstractArray{Item}, item, index) where Item =
    if isa(item, Item)
        @inbounds array[index] = item
        array
    else
        setindex_widen_up_to(array, item, index)
    end
setindex_widen_up_to(arrays::ZippedArrays, items, index...) =
    @inbounds zip((let index = index
        (array, item) -> maybe_setindex_widen_up_to(array, item, index...)
    end).(arrays.arrays, items)...)

maybe_push_widen(array::AbstractArray{Item}, item) where Item =
    if isa(item, Item)
        push!(array, item)
        array
    else
        push_widen(array, item)
    end
push_widen(arrays::ZippedArrays, items) =
    @inbounds zip(maybe_push_widen.(arrays.arrays, items)...)
