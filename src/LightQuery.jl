module LightQuery

import Base: axes, collect_similar, collect_to!, copyto!, eltype, empty, first,
    get, getindex, getproperty, grow_to!, haskey, IndexStyle, isless,
    IteratorEltype, IteratorSize, length, iterate, merge, NamedTuple, ndims,
    parent, push!, setindex!, size, show, similar, view, zip
@static if VERSION >= v"1.1"
    import Base: push_widen, setindex_widen_up_to
end
using Base: _collect, @default_eltype, EltypeUnknown, Generator, HasEltype,
    HasLength, HasShape, isvatuple, @pure, promote_typejoin,
    @propagate_inbounds, SizeUnknown, tail
import Base.Iterators: take
using Base.Iterators: Filter
using Base.Meta: quot
using Compat: hasproperty
using CSV: getcell, getfile, getrow, Row
using IterTools: @ifsomething
import MacroTools
using MacroTools: @capture
using Markdown: MD, Table
using Tables: Schema

include("utilities.jl")
include("macros.jl")
include("columns.jl")
include("Index.jl")
include("rows.jl")
include("make_columns.jl")
include("pivot.jl")
include("compat.jl")

end
