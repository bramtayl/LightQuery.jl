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
make_index(zipped::Zip, states) =
    Index(map_unrolled(make_index, get_columns(zipped), states))

previous_index(something, index::Index) =
    previous_index(parent(something), index)
previous_index(zipped::Zip, index::Index) =
    Index(map_unrolled(previous_index, get_columns(zipped), index.inner))
previous_index(array::AbstractArray, index::Index) = Index(index.inner - 1)

last_index(array::AbstractArray) = Index(last(LinearIndices(array)))
last_index(zipped::Zip) =
    Index(map_unrolled(last_index, get_columns(zipped)))
last_index(iterator) = last_index(parent(iterator))

@propagate_inbounds getindex(array::AbstractArray, index::Index) =
    getindex(array, index.inner)
@propagate_inbounds getindex(mapped::Generator, index::Index) =
    mapped.f(getindex(parent(mapped), index))
@propagate_inbounds getindex(filtered::Filter, index::Index) =
    getindex(parent(filtered), index)
@propagate_inbounds getindex(zipped::Zip, index::Index) =
    map_unrolled(
        getindex,
        get_columns(zipped),
        index.inner
    )

@propagate_inbounds view(array::AbstractArray, indexes::IndexRange) =
    view(array, indexes.start:indexes.stop)
@propagate_inbounds view(mapped::Generator, indexes::IndexRange) =
    Generator(mapped.f, view(parent(mapped), indexes))
@propagate_inbounds view(filtered::Filter, indexes::IndexRange) =
    Filter(filtered.f, view(parent(filtered), indexes))
@propagate_inbounds view(zipped::Zip, indexes::IndexRange) =
    zip(map_unrolled(
        view,
        get_columns(zipped),
        map_unrolled(:, indexes.start, indexes.stop)
    )...)

# piracy
parent(mapped::Generator) = mapped.iter
parent(filtered::Filter) = filtered.itr
