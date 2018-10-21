module LightQuery

include("Nameless.jl")

import Base: map, join, count

import DataFrames
import DataFramesMeta
import SplitApplyCombine
import QueryOperators

using QueryOperators: Enumerable
using DataFrames: AbstractDataFrame, GroupedDataFrame, GroupApplied, groupby

export where
where(data::Union{AbstractDataFrame, GroupedDataFrame}, n::Nameless) =
    DataFramesMeta.where(data, n.f)
where(data::Enumerable, n::Nameless) =
    QueryOperators.filter(data, n.f, n.expression)

export Then
struct Then end
export Descending
struct Descending end
export order
order(data::Union{AbstractDataFrame, GroupedDataFrame}, n::Nameless) =
    DataFramesMeta.orderby(data, n.f)
order(data::Enumerable, n::Nameless) =
    QueryOperators.orderby(data, n.f, n.expression)
order(::Then, data::Enumerable, n::Nameless) =
    QueryOperators.thenby(data, n.f, n.expression)
order(::Then, ::Descending, data::Enumerable, n::Nameless) =
    QueryOperators.thenby_descending(data, n.f, n.expression)
order(::Descending, data::Enumerable, n::Nameless) =
    QueryOperators.orderby_descending(data, n.f, n.expression)

export group
group(data::Enumerable, n::Nameless) =
    QueryOperators.groupby(data::Enumerable, n.f, n.expression)
group(data::AbstractDataFrame, n) =
    DataFrames.groupby(data, n)
group(data, n) =
    SplitApplyCombine.group(n, data)

export transform
transform(data::Union{AbstractDict, AbstractDataFrame, GroupedDataFrame}; kwargs...) =
    DataFramesMeta.transform(data; pairs(map(n -> n.f, kwargs.data))...)

export based_on
based_on(d::AbstractDataFrame; kwargs...) = DataFrame(; map(f -> f(d), kwargs.data)...)
based_on(data::Enumerable, n::Nameless) = QueryOperators.map(data, n.f, n.expression)

map(n::Nameless, data::GroupApplied) = map(n.f, data)

count(n::Nameless, data::Enumerable) =
    QueryOperators.count(data, n.f, n.expression)

struct Group end
struct Left end

join(data1::Enumerable, data2::Enumerable, n1::Nameless, n2::Nameless, n3::Nameless) =
    QueryOperators.join(data1, data2, n1.f, n1.expression, n2.f, n2.expression, n3.f, n3.expression)
join(::Group, data1::Enumerable, data2::Enumerable, n1::Nameless, n2::Nameless, n3::Nameless) =
    QueryOperators.groupjoin(data1, data2, n1.f, n1.expression, n2.f, n2.expression, n3.f, n3.expression)
join(::Left, ::Group, data1::Enumerable, data2::Enumerable, args...) =
    SplitApplyCombine.leftgroupjoin(data1, data2, args...)

mapmany(n1::Nameless, n2::Nameless, data::Enumerable) =
    QueryOperators.mapmany(data, n1.f, n1.expression, n2.f, n2.expression)
mapmany(f, args...) =
    SplitApplyCombine.mapmany(f, args...)

end
