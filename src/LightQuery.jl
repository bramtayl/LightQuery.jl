module LightQuery

import Base: ==, !=, !, &, |, axes, coalesce, collect_similar, collect_to!,
    copyto!, eltype, empty, first, get, getindex, getproperty, grow_to!, haskey,
    isequal, ifelse, in, IndexStyle, IteratorEltype, IteratorSize, isless,
    ismissing, length, iterate, merge, NamedTuple, occursin, push!, setindex!,
    size, show, similar, startswith, view, zip
@static if VERSION >= v"1.1"
    import Base: push_widen, setindex_widen_up_to
end
using Base: argument_datatype, _collect, @default_eltype, diff_names,
    EltypeUnknown, Generator, HasEltype, HasLength, HasShape, isvatuple, @pure,
    promote_typejoin, @propagate_inbounds, SizeUnknown, tail
import Base.Iterators: flatten, take, drop
using Base.Iterators: Filter, Zip
@static if VERSION < v"1.1"
    using Base.Iterators: Zip2
end
using Base.Meta: quot
using Compat: hasproperty
using Core: Bool, TypeofBottom
using CSV: getcell, getfile, getrow, Row
using IterTools: @ifsomething
import MacroTools
using MacroTools: @capture
using MappedArrays: mappedarray
using Markdown: MD, Table
using Tables: Schema, schema
export flatten

include("utilities.jl")
include("macros.jl")
include("rows.jl")
include("columns.jl")
include("make_columns.jl")
include("pivot.jl")
include("compat.jl")
# include("SQL.jl")

end
