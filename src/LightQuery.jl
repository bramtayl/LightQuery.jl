module LightQuery

import Base: axes, collect_similar, copyto!, eltype, empty, get, getindex,
    getproperty, haskey, IndexStyle, IteratorEltype, IteratorSize, isless,
    LinearIndices, length, iterate, merge, NamedTuple, push!, push_widen,
    startswith, size, setindex!, setindex_widen_up_to, show, similar, view, zip
using Base: _collect, @default_eltype, diff_names, EltypeUnknown, Generator,
    HasEltype, HasLength, HasShape, @pure, promote_op, @propagate_inbounds,
    SizeUnknown, sym_in, tail
using Base.Iterators: Filter, flatten, product, take, Zip, _zip_iterator_eltype,
    _zip_iterator_size
using Base.Meta: quot
using IterTools: @ifsomething
import MacroTools
using MacroTools: @capture
using MappedArrays: mappedarray
using Markdown: MD, Table
using Tables: Schema, schema
export Generator, Filter, flatten

include("utilities.jl")
include("macros.jl")
include("Unzip.jl")
include("rows.jl")
include("columns.jl")
include("pivot.jl")

end
