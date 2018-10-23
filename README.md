# LightQuery

[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://bramtayl.github.io/LightQuery.jl/latest)
[![Build Status](https://travis-ci.org/bramtayl/LightQuery.jl.svg?branch=master)](https://travis-ci.org/bramtayl/LightQuery.jl)
[![CodeCov](https://codecov.io/gh/bramtayl/LightQuery.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bramtayl/LightQuery.jl)

Here's some examples

```julia
using DataFrames: DataFrame, combine
using Statistics: mean

df = DataFrame(x = 1:10, a = 1:10, b = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5])

df |>
    (@_ transform(_, y = (@_ 10 * _.x))) |>
    (@_ where(_, @_ _.a .> 2))|>
    (@_ group(_, :b)) |>
    (@_ map(
        (@_ based_on(_,
            meanX = (@_ mean(_.x)),
            meanY = (@_ mean(_.y))
        )),
        _
    )) |>
    combine |>
    (@_ order(_, @_ _.meanX)



using QueryOperators: query, key
df = DataFrame(a=[1,1,2,3], b=[4,5,6,8])

df |>
    query |>
    (@_ group(_, @_ _.a)) |>
    (@_ based_on(_, (@_ (a = key(_), b = mean(_.b))))) |>
    (@_ where(_, @_ _.b > 5)) |>
    (@_ order(Descending(), _, @_ _.b)) |>
    DataFrame
```
