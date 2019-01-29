# LightQuery.jl

For an example of how to use this package, see the demo below, which follows the
tutorial
[here](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html). A
copy of the flights data is included in the test folder of this package.

The biggest difference between this package and dplyr is that you have to
explicitly move your data back and forth between rows (a vector of named tuples)
and columns (a named tuple of vectors) depending on the kind of operation you
want to do. Another inconvenience is that when you are moving from rows to
columns, in many cases, you will have to re-specify the column names (except in
certain cases). This is inconvenient but prevents this package from having to
rely on inference.

You can easily convert most objects to named tuples using [`named_tuple`](@ref).
As a named tuple, the data will be in a column-wise form. If you want to display
it, you can use [`pretty`](@ref) to hack the show methods of `DataFrame`s.

So read in flights, convert it into a named tuple, and remove the row-number
column (which reads in without a name). This package comes with its own chaining
macro [`@>`](@ref), which I'll make heavy use of.

```jldoctest
julia> using LightQuery

julia> import CSV

julia> flights =
          @> CSV.read("flights.csv", missingstring = "NA") |>
          named_tuple |>
          remove(_, Symbol(""))

julia> pretty(flights)
336776×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │
│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │
│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │
│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │
│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │
│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │
│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │
│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │
```

The [`rows`](@ref) iterator will convert the data to row-wise form.
[`when`](@ref) will filter the data. You can make anonymous functions
 with [`@_`](@ref).

To display row-wise data, first, convert back to a columns-wise format with
[`autocolumns`](@ref).

```jldoctest
julia> using LightQuery

julia> @> flights |>
          rows |>
          when(_, @_ _.month == 1 && _.day == 1) |>
          autocolumns |>
          pretty
842×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│     │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├─────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1   │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2   │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3   │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4   │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5   │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6   │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7   │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 835 │ 2013   │ 1      │ 1      │ 2343     │ 1724           │ 379       │
│ 836 │ 2013   │ 1      │ 1      │ 2353     │ 2359           │ -6        │
│ 837 │ 2013   │ 1      │ 1      │ 2353     │ 2359           │ -6        │
│ 838 │ 2013   │ 1      │ 1      │ 2356     │ 2359           │ -3        │
│ 839 │ 2013   │ 1      │ 1      │ missing  │ 1630           │ missing   │
│ 840 │ 2013   │ 1      │ 1      │ missing  │ 1935           │ missing   │
│ 841 │ 2013   │ 1      │ 1      │ missing  │ 1500           │ missing   │
│ 842 │ 2013   │ 1      │ 1      │ missing  │ 600            │ missing   │
```

You can arrange rows with [`order_by`](@ref). Here, the currying version of
[`select`](@ref) comes in handy.

```jldoctest
julia> by_date =
          @> flights |>
          rows |>
          order_by(_, select(:year, :month, :day));

julia> @> by_date |>
          autocolumns |>
          pretty
336776×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 336769 │ 2013   │ 12     │ 31     │ missing  │ 1500           │ missing   │
│ 336770 │ 2013   │ 12     │ 31     │ missing  │ 1430           │ missing   │
│ 336771 │ 2013   │ 12     │ 31     │ missing  │ 855            │ missing   │
│ 336772 │ 2013   │ 12     │ 31     │ missing  │ 705            │ missing   │
│ 336773 │ 2013   │ 12     │ 31     │ missing  │ 825            │ missing   │
│ 336774 │ 2013   │ 12     │ 31     │ missing  │ 1615           │ missing   │
│ 336775 │ 2013   │ 12     │ 31     │ missing  │ 600            │ missing   │
│ 336776 │ 2013   │ 12     │ 31     │ missing  │ 830            │ missing   │
```

You can also pass in keyword arguments to `sort!` via `orderby`, like
`rev = true`. The difference from the dplyr output here is caused by how `sort!`
handles missing data in Julia.

```jldoctest
julia> @> flights |>
          rows |>
          order(_, select(:arr_delay), rev = true) |>
          autocolumns |>
          pretty
336776×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 1525     │ 1530           │ -5        │
│ 2      │ 2013   │ 1      │ 1      │ 1528     │ 1459           │ 29        │
│ 3      │ 2013   │ 1      │ 1      │ 1740     │ 1745           │ -5        │
│ 4      │ 2013   │ 1      │ 1      │ 1807     │ 1738           │ 29        │
│ 5      │ 2013   │ 1      │ 1      │ 1939     │ 1840           │ 59        │
│ 6      │ 2013   │ 1      │ 1      │ 1952     │ 1930           │ 22        │
│ 7      │ 2013   │ 1      │ 1      │ 2016     │ 1930           │ 46        │
⋮
│ 336769 │ 2013   │ 5      │ 7      │ 2054     │ 2055           │ -1        │
│ 336770 │ 2013   │ 5      │ 13     │ 657      │ 700            │ -3        │
│ 336771 │ 2013   │ 5      │ 2      │ 1926     │ 1929           │ -3        │
│ 336772 │ 2013   │ 5      │ 4      │ 1816     │ 1820           │ -4        │
│ 336773 │ 2013   │ 5      │ 2      │ 1947     │ 1949           │ -2        │
│ 336774 │ 2013   │ 5      │ 6      │ 1826     │ 1830           │ -4        │
│ 336775 │ 2013   │ 5      │ 20     │ 719      │ 735            │ -16       │
│ 336776 │ 2013   │ 5      │ 7      │ 1715     │ 1729           │ -14       │
```

In the original column-wise form, you can [`select`](@ref) or [`remove`](@ref)
columns.

```jldoctest
julia> @> flights |>
          select(_, :year, :month, :day) |>
          pretty
336776×3 DataFrames.DataFrame
│ Row    │ year   │ month  │ day    │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │
├────────┼────────┼────────┼────────┤
│ 1      │ 2013   │ 1      │ 1      │
│ 2      │ 2013   │ 1      │ 1      │
│ 3      │ 2013   │ 1      │ 1      │
│ 4      │ 2013   │ 1      │ 1      │
│ 5      │ 2013   │ 1      │ 1      │
│ 6      │ 2013   │ 1      │ 1      │
│ 7      │ 2013   │ 1      │ 1      │
⋮
│ 336769 │ 2013   │ 9      │ 30     │
│ 336770 │ 2013   │ 9      │ 30     │
│ 336771 │ 2013   │ 9      │ 30     │
│ 336772 │ 2013   │ 9      │ 30     │
│ 336773 │ 2013   │ 9      │ 30     │
│ 336774 │ 2013   │ 9      │ 30     │
│ 336775 │ 2013   │ 9      │ 30     │
│ 336776 │ 2013   │ 9      │ 30     │

julia> @> flights |>
          remove(_, :year, :month, :day) |>
          pretty
336776×16 DataFrames.DataFrame. Omitted printing of 11 columns
│ Row    │ dep_time │ sched_dep_time │ dep_delay │ arr_time │ sched_arr_time │
│        │ Int64⍰   │ Int64⍰         │ Int64⍰    │ Int64⍰   │ Int64⍰         │
├────────┼──────────┼────────────────┼───────────┼──────────┼────────────────┤
│ 1      │ 517      │ 515            │ 2         │ 830      │ 819            │
│ 2      │ 533      │ 529            │ 4         │ 850      │ 830            │
│ 3      │ 542      │ 540            │ 2         │ 923      │ 850            │
│ 4      │ 544      │ 545            │ -1        │ 1004     │ 1022           │
│ 5      │ 554      │ 600            │ -6        │ 812      │ 837            │
│ 6      │ 554      │ 558            │ -4        │ 740      │ 728            │
│ 7      │ 555      │ 600            │ -5        │ 913      │ 854            │
⋮
│ 336769 │ 2307     │ 2255           │ 12        │ 2359     │ 2358           │
│ 336770 │ 2349     │ 2359           │ -10       │ 325      │ 350            │
│ 336771 │ missing  │ 1842           │ missing   │ missing  │ 2019           │
│ 336772 │ missing  │ 1455           │ missing   │ missing  │ 1634           │
│ 336773 │ missing  │ 2200           │ missing   │ missing  │ 2312           │
│ 336774 │ missing  │ 1210           │ missing   │ missing  │ 1330           │
│ 336775 │ missing  │ 1159           │ missing   │ missing  │ 1344           │
│ 336776 │ missing  │ 840            │ missing   │ missing  │ 1020           │
```

You can also rename columns. Because constants (currently) do not propagate
through keyword arguments in Julia, it's smart to wrap column names with
[`Name`](@ref).

```jldoctest
julia> @> flights |>
          rename(_, tail_num = Name(:tailnum)) |>
          pretty
336776×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │
│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │
│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │
│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │
│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │
│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │
│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │
│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │
```

You can add new columns with transform. If you want to refer to previous
columns, you'll have to transform twice.

```jldoctest
julia> @> flights |>
          transform(_,
                    gain = _.arr_delay .- _.dep_delay,
                    speed = _.distance ./ _.air_time .* 60
          ) |>
          transform(_,
                    gain_per_hour = _.gain ./ (_.air_time / 60)
          ) |>
          pretty
336776×22 DataFrames.DataFrame. Omitted printing of 16 columns
│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │
│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │
│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │
│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │
│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │
│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │
│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │
⋮
│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │
│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │
│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │
│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │
│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │
│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │
│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │
│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │
```

No summarize here, but you can just directly access columns:

```jldoctest
julia> using Statistics: mean;

julia> mean(skipmissing(flights.dep_delay))
12.639070257304708
```

I don't provide a export a sample function here, but StatsBase does.

[`Group`](@ref)ing here works differently than in dplyr:

- You can only [`order_by`](@ref) sorted data. To let Julia know that the data
has been sorted, you need to explicitly wrap the data with [`By`](@ref).

- Second, groups return a pair, matching the key to the sub-data-frame. So:

```jldoctest
julia> by_tailnum =
          @> flights |>
          rows |>
          order(_, select(:tailnum)) |>
          By(_, select(:tailnum)) |>
          Group;

julia> pair = first(by_tailnum);

julia> pair.first
(tailnum = "D942DN",)

julia> @> pair.second |>
          autocolumns |>
          pretty
4×19 DataFrames.DataFrame. Omitted printing of 13 columns
│ Row │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │
│     │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │
├─────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤
│ 1   │ 2013   │ 2      │ 11     │ 1508     │ 1400           │ 68        │
│ 2   │ 2013   │ 3      │ 23     │ 1340     │ 1300           │ 40        │
│ 3   │ 2013   │ 3      │ 24     │ 859      │ 835            │ 24        │
│ 4   │ 2013   │ 7      │ 5      │ 1253     │ 1259           │ -6        │
```

- Third, you have to explicity use [`over`](@ref) to map over groups.

So putting it all together, here is the example from the dplyr docs, LightQuery
style. This is the first time in this example where `autocolumns` won't work.
You'll have to explicitly use [`columns`](@ref) for the last call.

```jldoctest
julia> @> by_tailnum |>
          over(_, @_ begin
                    sub_frame = autocolumns(_.second)
                    transform(_.first,
                              count = length(_.second),
                              distance = sub_frame.distance |> skipmissing |> mean,
                              delay = sub_frame.arr_delay |> skipmissing |> mean
                    )
          end) |>
          columns(_, :tailnum, :count, :distance, :delay) |>
          pretty
4044×4 DataFrames.DataFrame
│ Row  │ tailnum │ count │ distance │ delay    │
│      │ String⍰ │ Int64 │ Float64  │ Float64  │
├──────┼─────────┼───────┼──────────┼──────────┤
│ 1    │ D942DN  │ 4     │ 854.5    │ 31.5     │
│ 2    │ N0EGMQ  │ 371   │ 676.189  │ 9.98295  │
│ 3    │ N10156  │ 153   │ 757.948  │ 12.7172  │
│ 4    │ N102UW  │ 48    │ 535.875  │ 2.9375   │
│ 5    │ N103US  │ 46    │ 535.196  │ -6.93478 │
│ 6    │ N104UW  │ 47    │ 535.255  │ 1.80435  │
│ 7    │ N10575  │ 289   │ 519.702  │ 20.6914  │
⋮
│ 4037 │ N996DL  │ 102   │ 897.304  │ 0.524752 │
│ 4038 │ N997AT  │ 44    │ 679.045  │ 16.3023  │
│ 4039 │ N997DL  │ 63    │ 867.762  │ 4.90323  │
│ 4040 │ N998AT  │ 26    │ 593.538  │ 29.96    │
│ 4041 │ N998DL  │ 77    │ 857.818  │ 16.3947  │
│ 4042 │ N999DN  │ 61    │ 895.459  │ 14.3115  │
│ 4043 │ N9EAMQ  │ 248   │ 674.665  │ 9.23529  │
│ 4044 │ missing │ 2512  │ 710.258  │ NaN      │
```

For the n-distinct example, I've switched things around to be just a smidge
more efficient. This example shows how calling `columns` then `rows` is
sometimes necessary to trigger eager evaluation.


```jldoctest
julia> dest_tailnum =
          @> flights |>
          rows |>
          order(_, select(:dest, :tailnum)) |>
          By(_, select(:dest, :tailnum)) |>
          Group |>
          over(_, @_ transform(_.first,
                    flights = length(_.second)
          )) |>
          columns(_, :dest, :tailnum, :flights) |>
          rows |>
          By(_, select(:dest)) |>
          Group |>
          over(_, @_ transform(_.first,
                    flights = sum(autocolumns(_.second).flights),
                    planes = length(_.second)
          )) |>
          columns(_, :flights, :planes) |>
          pretty
105×2 DataFrames.DataFrame
│ Row │ flights │ planes │
│     │ Int64   │ Int64  │
├─────┼─────────┼────────┤
│ 1   │ 254     │ 108    │
│ 2   │ 265     │ 58     │
│ 3   │ 439     │ 172    │
│ 4   │ 8       │ 6      │
│ 5   │ 17215   │ 1180   │
│ 6   │ 2439    │ 993    │
│ 7   │ 275     │ 159    │
⋮
│ 98  │ 4339    │ 960    │
│ 99  │ 522     │ 87     │
│ 100 │ 1761    │ 383    │
│ 101 │ 7466    │ 1126   │
│ 102 │ 315     │ 105    │
│ 103 │ 101     │ 60     │
│ 104 │ 631     │ 273    │
│ 105 │ 1036    │ 176    │
```

As I mentioned before, you can use `By` instead of `order_by` if you know a
dataset has been pre-sorted. This makes rolling up data-sets fairly easy.

```jldoctest
julia> per_day =
          @> by_date |>
          By(_, select(:year, :month, :day)) |>
          Group |>
          over(_, @_ transform(_.first, flights = length(_.second))) |>
          columns(_, :year, :month, :day, :flights);

julia> pretty(per_day)
365×4 DataFrames.DataFrame
│ Row │ year  │ month │ day   │ flights │
│     │ Int64 │ Int64 │ Int64 │ Int64   │
├─────┼───────┼───────┼───────┼─────────┤
│ 1   │ 2013  │ 1     │ 1     │ 842     │
│ 2   │ 2013  │ 1     │ 2     │ 943     │
│ 3   │ 2013  │ 1     │ 3     │ 914     │
│ 4   │ 2013  │ 1     │ 4     │ 915     │
│ 5   │ 2013  │ 1     │ 5     │ 720     │
│ 6   │ 2013  │ 1     │ 6     │ 832     │
│ 7   │ 2013  │ 1     │ 7     │ 933     │
⋮
│ 358 │ 2013  │ 12    │ 24    │ 761     │
│ 359 │ 2013  │ 12    │ 25    │ 719     │
│ 360 │ 2013  │ 12    │ 26    │ 936     │
│ 361 │ 2013  │ 12    │ 27    │ 963     │
│ 362 │ 2013  │ 12    │ 28    │ 814     │
│ 363 │ 2013  │ 12    │ 29    │ 888     │
│ 364 │ 2013  │ 12    │ 30    │ 968     │
│ 365 │ 2013  │ 12    │ 31    │ 776     │

julia> per_month =
          @> per_day|>
          rows |>
          By(_, select(:year, :month)) |>
          Group |>
          over(_, @_ transform(_.first,
                    flights = sum(autocolumns(_.second).flights))) |>
          columns(_, :year, :month, :flights);

julia> pretty(per_month)
12×3 DataFrames.DataFrame
│ Row │ year  │ month │ flights │
│     │ Int64 │ Int64 │ Int64   │
├─────┼───────┼───────┼─────────┤
│ 1   │ 2013  │ 1     │ 27004   │
│ 2   │ 2013  │ 2     │ 24951   │
│ 3   │ 2013  │ 3     │ 28834   │
│ 4   │ 2013  │ 4     │ 28330   │
│ 5   │ 2013  │ 5     │ 28796   │
│ 6   │ 2013  │ 6     │ 28243   │
│ 7   │ 2013  │ 7     │ 29425   │
│ 8   │ 2013  │ 8     │ 29327   │
│ 9   │ 2013  │ 9     │ 27574   │
│ 10  │ 2013  │ 10    │ 28889   │
│ 11  │ 2013  │ 11    │ 27268   │
│ 12  │ 2013  │ 12    │ 28135   │

julia> per_year =
          @> per_month |>
          rows |>
          By(_, select(:year)) |>
          Group |>
          over(_, @_ transform(_.first,
                    flights = sum(autocolumns(_.second).flights))) |>
          columns(_, :year, :flights);

julia> pretty(per_year)
1×2 DataFrames.DataFrame
│ Row │ year  │ flights │
│     │ Int64 │ Int64   │
├─────┼───────┼─────────┤
│ 1   │ 2013  │ 336776  │
```

Here's the example in the dplyr docs for piping:

```jldoctest
julia> @> by_date |>
          By(_, select(:year, :month, :day)) |>
          Group |>
          over(_, @_ begin
                    sub_frame = autocolumns(_.second)
                    transform(_.first,
                              arr = sub_frame.arr_delay |> skipmissing |> mean,
                              dep = sub_frame.dep_delay |> skipmissing |> mean
                    )
          end) |>
          when(_, @_ _.arr > 30 || _.dep > 30) |>
          columns(_, :year, :month, :day, :arr, :dep) |>
          pretty
49×5 DataFrames.DataFrame
│ Row │ year  │ month │ day   │ arr     │ dep     │
│     │ Int64 │ Int64 │ Int64 │ Float64 │ Float64 │
├─────┼───────┼───────┼───────┼─────────┼─────────┤
│ 1   │ 2013  │ 1     │ 16    │ 34.2474 │ 24.6129 │
│ 2   │ 2013  │ 1     │ 31    │ 32.6029 │ 28.6584 │
│ 3   │ 2013  │ 2     │ 11    │ 36.2901 │ 39.0736 │
│ 4   │ 2013  │ 2     │ 27    │ 31.2525 │ 37.7633 │
│ 5   │ 2013  │ 3     │ 8     │ 85.8622 │ 83.5369 │
│ 6   │ 2013  │ 3     │ 18    │ 41.2919 │ 30.118  │
│ 7   │ 2013  │ 4     │ 10    │ 38.4123 │ 33.0237 │
⋮
│ 42  │ 2013  │ 10    │ 11    │ 18.923  │ 31.2318 │
│ 43  │ 2013  │ 12    │ 5     │ 51.6663 │ 52.328  │
│ 44  │ 2013  │ 12    │ 8     │ 36.9118 │ 21.5153 │
│ 45  │ 2013  │ 12    │ 9     │ 42.5756 │ 34.8002 │
│ 46  │ 2013  │ 12    │ 10    │ 44.5088 │ 26.4655 │
│ 47  │ 2013  │ 12    │ 14    │ 46.3975 │ 28.3616 │
│ 48  │ 2013  │ 12    │ 17    │ 55.8719 │ 40.7056 │
│ 49  │ 2013  │ 12    │ 23    │ 32.226  │ 32.2541 │
```

Again, for inference reasons, natural joins won't work. I only provide one join
at the moment, but it's super efficient. Let's start by reading in airlines and
letting julia konw that it's already sorted by `:carrier`.

```jldoctest
julia> airlines =
          @> CSV.read("airlines.csv", missingstring = "NA") |>
          named_tuple |>
          remove(_, Symbol("")) |>
          rows |>
          By(_, select(:carrier));
```

If we want to join this data into the flights data, here's what we do.
`LeftJoin` requires not only presorted but **unique** keys. Of course,
there are multiple flights from the same airline, so we need to group first.
Then, we tell Julia that the groups are themselves sorted (by the first item,
the key). Finally we can join in the airline data. But the results are a bit
tricky. Let's take a look at the first item. Just like the dplyr manual, I'm
only using a few of the columns from `flights` for demonstration.

```jldoctest
julia> sample_join =
          @> flights |>
          select(_, :year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier) |>
          rows |>
          order(_, select(:carrier)) |>
          By(_, select(:carrier)) |>
          Group |>
          By(_, first) |>
          LeftJoin(_, airlines);

julia> first_join = first(sample_join);
```

We end up getting a group on the left, and a row on the right.

```jldoctest
julia> first_join.first.first
(carrier = "9E",)

julia> @> first_join.first.second |>
            autocolumns |>
            pretty
18460×8 DataFrames.DataFrame. Omitted printing of 1 columns
│ Row   │ year   │ month  │ day    │ hour   │ origin  │ dest    │ tailnum │
│       │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰ │ String⍰ │ String⍰ │ String⍰ │
├───────┼────────┼────────┼────────┼────────┼─────────┼─────────┼─────────┤
│ 1     │ 2013   │ 1      │ 1      │ 8      │ JFK     │ MSP     │ N915XJ  │
│ 2     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ IAD     │ N8444F  │
│ 3     │ 2013   │ 1      │ 1      │ 14     │ JFK     │ BUF     │ N920XJ  │
│ 4     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ SYR     │ N8409N  │
│ 5     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ ROC     │ N8631E  │
│ 6     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ BWI     │ N913XJ  │
│ 7     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ ORD     │ N904XJ  │
⋮
│ 18453 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ IAD     │ N8790A  │
│ 18454 │ 2013   │ 9      │ 30     │ 20     │ LGA     │ TYS     │ N8924B  │
│ 18455 │ 2013   │ 9      │ 30     │ 19     │ JFK     │ PHL     │ N602XJ  │
│ 18456 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ DCA     │ N602LR  │
│ 18457 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ BWI     │ N8423C  │
│ 18458 │ 2013   │ 9      │ 30     │ 18     │ JFK     │ BUF     │ N906XJ  │
│ 18459 │ 2013   │ 9      │ 30     │ 14     │ JFK     │ DCA     │ missing │
│ 18460 │ 2013   │ 9      │ 30     │ 22     │ LGA     │ SYR     │ missing │

julia> first_join.second
(carrier = "9E", name = "Endeavor Air Inc.")
```

If you want to collect your results into a flat new dataframe, you need to do a
bit of surgery, including making use of `Iterators.flatten`:

```jldoctest
julia> @> sample_join |>
          over(_, @_ begin
                    left_rows = _.first.second
                    right_row = _.second
                    over(left_rows, @_ transform(_,
                              airline_name = right_row.name))
          end) |>
          Iterators.flatten(_) |>
          columns(_, :year, :month, :day, :hour, :origin, :dest, :tailnum,
                    :carrier, :airline_name) |>
          pretty
336776×9 DataFrames.DataFrame. Omitted printing of 1 columns
│ Row    │ year  │ month │ day   │ hour  │ origin │ dest   │ tailnum │ carrier │
│        │ Int64 │ Int64 │ Int64 │ Int64 │ String │ String │ String⍰ │ String  │
├────────┼───────┼───────┼───────┼───────┼────────┼────────┼─────────┼─────────┤
│ 1      │ 2013  │ 1     │ 1     │ 8     │ JFK    │ MSP    │ N915XJ  │ 9E      │
│ 2      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ IAD    │ N8444F  │ 9E      │
│ 3      │ 2013  │ 1     │ 1     │ 14    │ JFK    │ BUF    │ N920XJ  │ 9E      │
│ 4      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ SYR    │ N8409N  │ 9E      │
│ 5      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ ROC    │ N8631E  │ 9E      │
│ 6      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ BWI    │ N913XJ  │ 9E      │
│ 7      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ ORD    │ N904XJ  │ 9E      │
⋮
│ 336769 │ 2013  │ 9     │ 27    │ 16    │ LGA    │ IAD    │ N514MJ  │ YV      │
│ 336770 │ 2013  │ 9     │ 27    │ 17    │ LGA    │ CLT    │ N925FJ  │ YV      │
│ 336771 │ 2013  │ 9     │ 28    │ 19    │ LGA    │ IAD    │ N501MJ  │ YV      │
│ 336772 │ 2013  │ 9     │ 29    │ 16    │ LGA    │ IAD    │ N518LR  │ YV      │
│ 336773 │ 2013  │ 9     │ 29    │ 17    │ LGA    │ CLT    │ N932LR  │ YV      │
│ 336774 │ 2013  │ 9     │ 30    │ 16    │ LGA    │ IAD    │ N510MJ  │ YV      │
│ 336775 │ 2013  │ 9     │ 30    │ 17    │ LGA    │ CLT    │ N905FJ  │ YV      │
│ 336776 │ 2013  │ 9     │ 30    │ 20    │ LGA    │ CLT    │ N924FJ  │ YV      │
```

```@index
```

```@autodocs
Modules = [LightQuery]
```
