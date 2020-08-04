module LightQuery

# TODO: remove take

import Base:
    axes,
    collect_similar,
    collect_to!,
    copyto!,
    eltype,
    empty,
    first,
    get,
    getindex,
    getproperty,
    grow_to!,
    haskey,
    hasproperty,
    IndexStyle,
    isless,
    IteratorEltype,
    IteratorSize,
    length,
    iterate,
    merge,
    NamedTuple,
    ndims,
    parent,
    @propagate_inbounds,
    propertynames,
    push!,
    setindex!,
    size,
    show,
    similar,
    view
@static if VERSION >= v"1.1"
    import Base: push_widen, setindex_widen_up_to
end
using Base:
    _collect,
    @default_eltype,
    DimensionMismatch,
    EltypeUnknown,
    Generator,
    HasEltype,
    HasLength,
    HasShape,
    isvatuple,
    @pure,
    SizeUnknown,
    tail
import Base.Iterators: flatten, take
using Base.Iterators: Filter
using Base.Meta: quot
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

end
