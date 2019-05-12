module LightQuery

import Base: axes, collect_similar, copyto!, eltype, empty, get, getindex,
    getproperty, haskey, IndexStyle, IteratorEltype, IteratorSize, isless,
    LinearIndices, length, iterate, merge, NamedTuple, push!, startswith, size,
    setindex!, show, similar, view, zip
using Base: argument_datatype, _collect, @default_eltype, diff_names,
    EltypeUnknown, Generator, HasEltype, HasLength, HasShape, isvarargtype,
    isvatuple, @pure, promote_op, @propagate_inbounds, SizeUnknown, sym_in, tail
using Base.Iterators: Filter, flatten, product, take, Zip
using Compat: fieldcount, hasproperty
using Core: TypeofBottom
using Base.Meta: quot
using IterTools: @ifsomething
import MacroTools
using MacroTools: @capture
using MappedArrays: mappedarray
using Markdown: MD, Table
using Tables: Schema, schema
export Generator, Filter, flatten

@static if VERSION < v"1.1"
    fieldtypes(T::Type) = ntuple(i -> fieldtype(T, i), fieldcount(T))

    using Base.Iterators: Zip2
    get_columns(zipped::Zip) = zipped.a, get_columns(zipped.z)...
    get_columns(zipped::Zip2) = zipped.a, zipped.b
else
    import Base: push_widen, setindex_widen_up_to

    get_columns(zipped::Zip) = zipped.is
end

include("utilities.jl")
include("macros.jl")
include("rows.jl")
include("columns.jl")
include("make_columns.jl")
include("pivot.jl")

@static if VERSION < v"1.1"
    @inline getindex(zipped::Zip2, index...) =
        partial_map(getindex_reverse, index, get_columns(zipped))
    @inline view(zipped::Zip2, index...) =
        zip(partial_map(view_reverse, index, get_columns(zipped))...)
    state_to_index(zipped::Zip2, state) =
        state_to_index(first(get_columns(zipped)), first(state))
    to_columns(rows::Generator{<: Zip2, <: Some{Name}}) =
        rows.f(get_columns(rows.iter))
end

end
