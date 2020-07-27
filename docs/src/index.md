# Usage and performance notes

LightQuery is highly optimized for long datasets with a small number of columns (< 100). The tradeoff is similar to the tradeoff between using StaticArrays and Arrays. It is strongly recommended to only select the columns you need before using LightQuery. Alternatively, you could use a package like DataFrames.

You can avoid most allocations in LightQuery by keeping your data pre-sorted. If your data is not pre-sorted, then the majority of run-time will likely be spent in sorting.

LightQuery requires that all of your columns have the same indices. The `Rows` constructor will check whether this is the case; to override these checks, use `@inbounds`.

LightQuery has trouble dealing with missing data represented as `Union{Missing, T}` due to performance issues in Base. Hopefully, these will get sorted out soon. In the mean-time, `DataValues` work.
