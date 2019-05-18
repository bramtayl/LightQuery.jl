@static if VERSION < v"1.1"

    get_columns(zipped::Zip) = zipped.a, get_columns(zipped.z)...
    get_columns(zipped::Zip2) = zipped.a, zipped.b

    @inline getindex(zipped::Zip2, index...) =
        partial_map(getindex_reverse, index, get_columns(zipped))
    @inline view(zipped::Zip2, index...) =
        zip(partial_map(view_reverse, index, get_columns(zipped))...)
    state_to_index(zipped::Zip2, state) =
        state_to_index(first(get_columns(zipped)), first(state))

    to_columns(rows::Generator{<: Zip2, <: Apply}) =
        rows.f(get_columns(rows.iter))

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
end
