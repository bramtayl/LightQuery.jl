@static if VERSION < v"1.1"
    # backport #30076 just for Rows
    function fieldtypes(type::Type)
        inner_fieldtype(index) = fieldtype(type, index)
        ntuple(inner_fieldtype, fieldcount(type))
    end

    get_columns(zipped::Zip) = zipped.a, get_columns(zipped.z)...
    get_columns(zipped::Zip2) = zipped.a, zipped.b

    @inline getindex(zipped::Zip2, index...) =
        partial_map(getindex_reverse, index, get_columns(zipped))
    @inline view(zipped::Zip2, index...) =
        zip(partial_map(view_reverse, index, get_columns(zipped))...)
    state_to_index(zipped::Zip2, state) =
        state_to_index(first(get_columns(zipped)), first(state))

    to_columns(rows::Generator{<: Zip2, <: Some{Name}}) =
        rows.f(get_columns(rows.iter))

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
else
    get_columns(zipped::Zip) = zipped.is
end
