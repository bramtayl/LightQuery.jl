module LightQuery

import Base: axes, collect_similar, collect_to!, copyto!, eltype, empty, first,
    get, getindex, getproperty, grow_to!, haskey, IndexStyle, isless,
    IteratorEltype, IteratorSize, length, iterate, merge, NamedTuple, ndims,
    parent, push!, setindex!, size, show, similar, view
@static if VERSION >= v"1.1"
    import Base: push_widen, setindex_widen_up_to
end
using Base: _collect, @default_eltype, DimensionMismatch, EltypeUnknown,
    Generator, HasEltype, HasLength, HasShape, isvatuple, @pure,
    @propagate_inbounds, SizeUnknown, tail
import Base.Iterators: take
using Base.Iterators: Filter
using Base.Meta: quot
using Compat: hasproperty
using CSV: getcolumn, Column, getrow, Row, File
using IterTools: @ifsomething
import MacroTools
using MacroTools: @capture
using Markdown: MD, Table

include("utilities.jl")
include("macros.jl")
include("columns.jl")
include("index.jl")
include("rows.jl")
include("make_columns.jl")
include("pivot.jl")
include("compat.jl")

end
