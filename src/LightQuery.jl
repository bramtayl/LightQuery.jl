module LightQuery

import Base: axes, collect_similar, copyto!, eltype, empty, getindex, getproperty,
    IndexStyle, IteratorEltype, IteratorSize, isless, LinearIndices, length, iterate,
    merge, push!, push_widen, size, setindex!, setindex_widen_up_to, show, similar,
    view, zip
using Base: _collect, @default_eltype, diff_names, EltypeUnknown, Generator,
    HasEltype, HasLength, HasShape, promote_op, @propagate_inbounds, SizeUnknown,
    sym_in
using Base.Iterators: Filter, flatten, product, take, Zip, _zip_iterator_eltype,
    _zip_iterator_size
using Base.Meta: quot
import CSV
using IterTools: @ifsomething
using MacroTools: @capture
using MappedArrays: mappedarray
using Markdown: MD, Table
export CSV, File, Generator, Filter, flatten

include("macros.jl")
include("Unzip.jl")
include("rows.jl")
include("columns.jl")
include("pivot.jl")

end
