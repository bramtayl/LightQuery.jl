function make_index(array::Array, next_state)
    next_state - 1
end
function make_index(array::AbstractArray, (axis, next_state))
    next_state
end
function make_index(something, next_state)
    make_index(parent(something), next_state)
end

function previous_index(something, index)
    previous_index(parent(something), index)
end
function previous_index(array::AbstractArray, index)
    index - 1
end

function last_index(array::AbstractArray)
    last(LinearIndices(array))
end
function last_index(iterator)
    last_index(parent(iterator))
end

# piracy

function parent(mapped::Generator)
    mapped.iter
end
function parent(filtered::Filter)
    filtered.itr
end
@propagate_inbounds function getindex(mapped::Generator, index)
    mapped.f(getindex(parent(mapped), index))
end
@propagate_inbounds function getindex(filtered::Filter, index)
    getindex(parent(filtered), index)
end
@propagate_inbounds function view(mapped::Generator, indexes)
    Generator(mapped.f, view(parent(mapped), indexes))
end
@propagate_inbounds function view(filtered::Filter, indexes)
    Filter(filtered.f, view(parent(filtered), indexes))
end
