@static if VERSION < v"1.1"

    head(zipped::Zip2) = zipped.a
    tail_or_end(zipped::Zip2) = zipped.a
    head(zipped::Zip) = zipped.a
    tail_or_end(zipped::Zip) = zipped.z

    make_index(zipped::Union{Zip2, Zip}, (head_state, tail_state)) =
        Index((
            make_index(head(zipped), head_state),
            make_index(tail_or_end(zipped), tail_state)
        ))

    function previous_index(zipped::Union{Zip2, Zip}, index::Index)
        head_state, tail_state = index.inner
        Index((
            previous_index(head(zipped), head_state),
            previous_index(tail_or_end(zipped), tail_state)
        ))
    end
    last_index(zipped::Union{Zip2, Zip}) = Index((
        last_index(head(zipped)),
        last_index(tail_or_end(zipped))
    ))
    @propagate_inbounds function getindex(zipped::Zip2, index::Index)
        head_state, tail_state = index.inner
        getindex(zipped.a, head_state), getindex(zipped.b, tail_state)
    end
    @propagate_inbounds function getindex(zipped::Zip, index::Index)
        head_state, tail_state = index.inner
        getindex(zipped.a, head_state), getindex(zipped.z, tail_state)...
    end
    @propagate_inbounds function view(zipped::Zip2, indexes::IndexRange)
        head_state_start, tail_state_start = indexes.start
        head_state_stop, tail_state_stop = indexes.stop
        zip(
            view(zipped.a, head_state_start:head_state_stop),
            view(zipped.b, tail_state_start:tail_state_stop)
        )
    end
    @propagate_inbounds function view(zipped::Zip, indexes::IndexRange)
        head_state_start, tail_state_start = indexes.start
        head_state_stop, tail_state_stop = indexes.stop
        zip(
            view(zipped.a, head_state_start:head_state_stop),
            view(zipped.z, tail_state_start:tail_state_stop)...
        )
    end

    # backport #30076 just for Rows
    function collect_to!(destination::Rows{Item}, iterator, offset, state) where Item
        # collect to destination array, checking the type of each result. if a result does not
        # match, widen the result type and re-dispatch.
        index = offset
        while true
            result = iterate(iterator, state)
            result === nothing && break
            item, state = result
            if item isa Item || typeof(item) === Item
                @inbounds destination[index] = item::Item
                index = index + 1
            else
                new = setindex_widen_up_to(destination, item, index)
                return collect_to!(new, iterator, index + 1, state)
            end
        end
        destination
    end

    @inline function setindex_widen_up_to(destination::AbstractArray{Item}, item, index) where Item
        new = similar(destination, promote_typejoin(Item, typeof(item)))
        copyto!(new, firstindex(new), destination, firstindex(destination), index - 1)
        @inbounds new[index] = item
        return new
    end

    function grow_to!(destination::Rows, iterator, state)
        Item = eltype(destination)
        result = iterate(iterator, state)
        while result !== nothing
            item, state = result
            if item isa Item || typeof(item) === Item
                push!(destination, item::Item)
            else
                new = push_widen(destination, item)
                return grow_to!(new, iterator, state)
            end
            result = iterate(iterator, state)
        end
        destination
    end

    @inline function push_widen(destination, item)
        new = sizehint!(empty(
            destination,
            promote_typejoin(eltype(destination), typeof(item))
        ), length(destination))
        if new isa AbstractSet
            # TODO: merge back these two branches when copy! is re-enabled for sets/vectors
            union!(new, destination)
        else
            append!(new, destination)
        end
        push!(new, item)
        new
    end
else
    get_columns(zipped::Zip) = zipped.is
    make_index(zipped::Zip, states) =
        Index(map_unrolled(make_index, get_columns(zipped), states))
    previous_index(zipped::Zip, index::Index) =
        Index(map_unrolled(previous_index, get_columns(zipped), index.inner))
    last_index(zipped::Zip) =
        Index(map_unrolled(last_index, get_columns(zipped)))
    @propagate_inbounds getindex(zipped::Zip, index::Index) =
        map_unrolled(
            getindex,
            get_columns(zipped),
            index.inner
        )
    @propagate_inbounds view(zipped::Zip, indexes::IndexRange) =
        zip(map_unrolled(
            view,
            get_columns(zipped),
            map_unrolled(:, indexes.start, indexes.stop)
        )...)
end
