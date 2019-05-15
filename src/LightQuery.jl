module LightQuery

import Base: axes, collect_similar, collect_to!, copyto!, eltype, empty, get,
    getindex, getproperty, grow_to!, haskey, IndexStyle, IteratorEltype,
    IteratorSize, isless, LinearIndices, length, iterate, merge, NamedTuple,
    push!, startswith, size, setindex!, show, similar, view, zip
@static if VERSION >= v"1.1"
    import Base: push_widen, setindex_widen_up_to
end
using Base: argument_datatype, _collect, @default_eltype, diff_names,
    EltypeUnknown, Generator, HasEltype, HasLength, HasShape, isvarargtype,
    isvatuple, @pure, promote_op, promote_typejoin, @propagate_inbounds,
    SizeUnknown, sym_in, tail
using Base.Iterators: Filter, flatten, product, take, Zip
@static if VERSION < v"1.1"
    using Base.Iterators: Zip2
end
using Base.Meta: quot
using Compat: fieldcount, hasproperty
using Core: TypeofBottom
using IterTools: @ifsomething
import MacroTools
using MacroTools: @capture
using MappedArrays: mappedarray
using Markdown: MD, Table
using Tables: Schema, schema
export Generator, Filter, flatten

include("utilities.jl")
include("macros.jl")
include("rows.jl")
include("columns.jl")
include("make_columns.jl")
include("pivot.jl")
include("compat.jl")

end
