# Usage and performance notes

You can avoid most allocations in LightQuery by keeping your data pre-sorted. If your data is not pre-sorted, then the majority of run-time will likely be spent in sorting.

LightQuery requires that all of your columns have the same indices. The `Rows` constructor will check whether this is the case; to override these checks, use `@inbounds`.
