struct Index{Inner}
    inner::Inner
end

struct IndexRange{Start, Stop}
    start::Start
    stop::Stop
end

function (:)(start::Index, stop::Index)
    IndexRange(start.inner, stop.inner)
end

function make_index(array::Array, next_index)
    Index(next_index - 1)
end
function make_index(array::AbstractArray, (axis, index))
    Index(index)
end
function make_index(something, state)
    make_index(parent(something), state)
end

function previous_index(something, index::Index)
    previous_index(parent(something), index)
end
function previous_index(array::AbstractArray, index::Index)
    Index(index.inner - 1)
end

function last_index(array::AbstractArray)
    Index(last(LinearIndices(array)))
end
function last_index(iterator)
    last_index(parent(iterator))
end

@propagate_inbounds function getindex(array::AbstractArray, index::Index)
    getindex(array, index.inner)
end
@propagate_inbounds function getindex(mapped::Generator, index::Index)
    mapped.f(getindex(parent(mapped), index))
end
@propagate_inbounds function getindex(filtered::Filter, index::Index)
    getindex(parent(filtered), index)
end
@propagate_inbounds function view(array::AbstractArray, indexes::IndexRange)
    view(array, indexes.start:indexes.stop)
end
@propagate_inbounds function view(mapped::Generator, indexes::IndexRange)
    Generator(mapped.f, view(parent(mapped), indexes))
end
@propagate_inbounds function view(filtered::Filter, indexes::IndexRange)
    Filter(filtered.f, view(parent(filtered), indexes))
end

# piracy
function parent(mapped::Generator)
    mapped.iter
end
function parent(filtered::Filter)
    filtered.itr
end
