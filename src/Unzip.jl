struct ModelArray{ElementType, NumberOfDimensions, Model, Rest <: Tuple} <:
    AbstractArray{ElementType, NumberOfDimensions}
    model::Model
    rest::Rest
end
ModelArray(model, rest...) =
    ModelArray{
        Tuple{eltype(model), eltype.(rest)...},
        ndims(model),
        typeof(model),
        typeof(rest)
    }(model, rest)
axes(array::ModelArray) = axes(array.model)
size(array::ModelArray) = size(array.model)
IndexStyle(array::ModelArray) = IndexStyle(array.model)
arrays(m::ModelArray) = (m.model, m.rest...)
function sizehint!(array::ModelArray, n)
	foreach(x -> sizehint!(x, n), arrays(array))
	array
end
@propagate_inbounds function getindex(array::ModelArray, index...)
    @propagate_inbounds inner(x) = x[index...]
    inner.(arrays(array))
end
@propagate_inbounds function setindex!(array::ModelArray, value, index...)
    @propagate_inbounds inner(x, value) = x[index...] = value
    inner.(arrays(array), value)
end
push!(array::ModelArray, value::Tuple) = push!.(arrays(array), value)

function similar(array::ModelArray, ::Type{ElementType}, dims::Dims) where {ElementType <: Union{}}
	error("Attempt to create a model array without an element type, likely due to inner function error. Try `first` to see what's up.")
end
function similar(array::ModelArray, ::Type, dims::Dims)
	@inline inner(i) = Array{Any}(undef, dims...)
	ModelArray(ntuple(inner, length(arrays(array)))...)
end
function similar(array::ModelArray, ::Type{ElementType}, dims::Dims) where {ElementType <: Tuple}
	@inline inner(i) = Array{fieldtype(ElementType, i)}(undef, dims...)
	ModelArray(ntuple(inner, length(arrays(array)))...)
end

empty(array::ModelArray{T}, ::Type{U} = T) where {T, U} = similar(array, U)

export unzip
"""
    unzip(it, n)

Unzip an iterator `it` which returns tuples of length `n`.

```jldoctest
julia> using LightQuery

julia> f(x) = (x, x + 1.0);

julia> unzip(over([1], f), 2)
([1], [2.0])

julia> unzip(over([1, missing], f), 2)
(Union{Missing, Int64}[1, missing], Union{Missing, Float64}[2.0, missing])

julia> unzip(zip([1], [1.0]), 2)
([1], [1.0])

julia> unzip([(1, 1.0)], 2)
([1], [1.0])

julia> unzip(over(when([1, missing, 2], x -> ismissing(x) || x > 1), f), 2)
(Union{Missing, Int64}[missing, 2], Union{Missing, Float64}[missing, 3.0])
```
"""
@inline unzip(it, n) = arrays(_collect(
    ModelArray(ntuple(x -> 1:1, n)...),
    it,
    IteratorEltype(it),
    IteratorSize(it)
))

maybe_setindex_widen_up_to(dest::AbstractArray{T}, el, i) where T =
    if isa(el, T)
        @inbounds dest[i] = el
        dest
    else
        setindex_widen_up_to(dest, el, i)
    end

setindex_widen_up_to(dest::ModelArray, el, i) =
    ModelArray(maybe_setindex_widen_up_to.(arrays(dest), el, i)...)


function maybe_push_widen(dest::AbstractArray{T}, el) where T
	if isa(el, T)
        push!(dest, el)
        dest
    else
        push_widen(dest, el)
    end
end

push_widen(dest::ModelArray, el) = ModelArray(maybe_push_widen.(arrays(dest), el)...)
