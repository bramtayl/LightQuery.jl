struct Index{Inner}
    inner::Inner
end

struct IndexRange{Start, Stop}
    start::Start
    stop::Stop
end

(:)(start::Index, stop::Index) =
    IndexRange(start.inner, stop.inner)

make_index(array::Array, next_index) = Index(next_index - 1)
make_index(array::AbstractArray, (axis, index)) = Index(index)
make_index(something, state) = make_index(parent(something), state)

previous_index(something, index::Index) =
    previous_index(parent(something), index)
previous_index(array::AbstractArray, index::Index) = Index(index.inner - 1)

last_index(array::AbstractArray) = Index(last(LinearIndices(array)))
last_index(iterator) = last_index(parent(iterator))

@propagate_inbounds getindex(array::AbstractArray, index::Index) =
    getindex(array, index.inner)
@propagate_inbounds getindex(mapped::Generator, index::Index) =
    mapped.f(getindex(parent(mapped), index))
@propagate_inbounds getindex(filtered::Filter, index::Index) =
    getindex(parent(filtered), index)

@propagate_inbounds view(array::AbstractArray, indexes::IndexRange) =
    view(array, indexes.start:indexes.stop)
@propagate_inbounds view(mapped::Generator, indexes::IndexRange) =
    Generator(mapped.f, view(parent(mapped), indexes))
@propagate_inbounds view(filtered::Filter, indexes::IndexRange) =
    Filter(filtered.f, view(parent(filtered), indexes))

# piracy
parent(mapped::Generator) = mapped.iter
parent(filtered::Filter) = filtered.itr
