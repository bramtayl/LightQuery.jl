# LightQuery

[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://bramtayl.github.io/LightQuery.jl/latest)
[![Build Status](https://travis-ci.org/bramtayl/LightQuery.jl.svg?branch=master)](https://travis-ci.org/bramtayl/LightQuery.jl)
[![CodeCov](https://codecov.io/gh/bramtayl/LightQuery.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bramtayl/LightQuery.jl)

Here's a quick way to replicate DataFramesMeta with this package.

```julia
using DataFrames: AbstractDataFrame, GroupedDataFrame, GroupApplied

where(d::AbstractDataFrame, f) = d[f(d), :]
orderby(d::AbstractDataFrame, f) = d[sortperm(f(d)), :]
function transform(d::AbstractDataFrame; kwargs...)
    d2 = copy(d)
        d2[k] = f(d2)
    end
    d2
end
based_on(d::AbstractDataFrame; kwargs...) = DataFrame(; map(f -> f(d), kwargs.data)...)
Base.map(n::Nameless, gd::GroupedDataFrame) = map(n.f, gd)
```

Now you can do all the operations in DataFramesMeta with a single macro!

```julia
using LightQuery: @_
using Statistics: mean
using DataFrames: DataFrame, groupby, rename!, combine

df = DataFrame(x = 1:10, a = 1:10, b = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5])

df |>
    (@_ transform(_, y = (@_ 10 * _.x))) |>
    (@_ where(_, @_ _.a .> 2)) |>
    (@_ groupby(_, :b)) |>
    (@_ map(
        (@_ based_on(_,
            meanX = (@_ mean(_.x)),
            meanY = (@_ mean(_.y))
        )),
        _
    )) |>
    combine |>
    (@_ orderby(_, (@_ _.meanX))) |>
    (@_ rename!(_, :b => :var)) |>
    (@_ _[[:meanX, :meanY, :var]])
```

Similar wrappers can be made for Query, though I don't provide a full example.

```julia
import QueryOperartors
import QueryOperators: Enumerable, count, join, groupjoin, mapmany, orderby, orderby_descending, thenby, thenby_descending

count(source::Enumerable, n::Nameless) =
    count(source, n.f, n.expression)

QueryOperators.filter(source::Enumerable, n::Nameless) =
    QueryOperators.filter(source, n.f, n.expression)

groupjoin(outer::Enumerable, inner::Enumerable, n1::Nameless, n2::Nameless, n3::Nameless) =
    groupjoin(outer, inner, n1.f, n1.expression, n2.f, n2.expression, n3.f, n3.expression)

join(outer::Enumerable, inner::Enumerable,  n1::Nameless, n2::Nameless, n3::Nameless) =
    join(outer, inner, n1.f, n1.expression, n2.f, n2.expression, n3.f, n3.expression)

QueryOperators.map(source::Enumerable, n::Nameless) =
    QueryOperators.map(source, n.f, n.expression)

mapmany(source::Enumerable, n1::Nameless, n2::Nameless) =
    mapmany(source, n1.f, n1.expression, n2.f, n2.expression)

orderby(source::Enumerable, n::Nameless) =
    orderby(source, n.f, n.expression)

orderby_descending(source::Enumerable, n::Nameless) =
    orderby_descending(source, n.f, n.expression)

thenby(source::Enumerable, n::Nameless) =
    thenby(source, n.f, n.expression)

thenby_descending(source::Enumerable, n::Nameless) =
    thenby_descending(source, n.f, n.expression)
```
