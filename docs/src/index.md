# Usage and performance notes

LightQuery is most performant when the number of columns is short compared to the number of rows. Otherwise, compile-time might swamp run-time, and I'd suggest using DataFrames instead. In addition, due to the limits of inference, LightQuery will not be performant if there are more than 30 columns.

You can avoid most allocations in LightQuery by keeping your data pre-sorted. If your data is not pre-sorted, then the majority of run-time will likely be spent in sorting.

LightQuery requires that all of your columns have the same indices. The `Rows` constructor will check whether this is the case; to override these checks, use `@inbounds`.
