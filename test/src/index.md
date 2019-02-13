# LightQuery.jl

# Introduction to LightQuery

Follows the tutorial [here](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html).
I'll make heavy use of the chaining macro `@>` and lazy calling macro `@_` included
in this package. The syntax here is in most cases more verbose but also more
flexible than dplyr. Fortunately, programming with LightQuery is much easier, so
define shortcuts.

## Data

Use `Peek` to view iterators of `NamedTuple`s. The data is stored column-wise;
`rows` is a lazy view.

```jldoctest dplyr
julia> using LightQuery

julia> flights =
        @> "flights.csv" |>
        CSV.read(_, allowmissing = :auto) |>
        named_tuple |>
        rows;

julia> Peek(flights)
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |
```

## Single table verbs

### Filter rows

`Filter` is re-exported from `Base.Iterators`.

```jldoctest dplyr
julia> @> flights |>
        Filter((@_ _.month == 1 && _.day == 1), _) |>
        Peek
Showing at most 4 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |
```

In some cases, a columnwise filter might be more efficient.

```jldoctest dplyr
julia> @> flights |>
        columns |>
        (_.month .== 1 .& _.day .== 1) |>
        view(flights, _) |>
        Peek
Showing 4 of 13936 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |
```

### Order rows

```jldoctest dplyr
julia> @> flights |>
        order(_, Names(:year, :month, :day)) |>
        Peek
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |
```

For performance, filter out instabilities.

```jldoctest dplyr
julia> @> flights |>
        order(_, Names(:arr_delay), (@_ !ismissing(_.arr_delay)), rev = true) |>
        Peek
Showing 4 of 327346 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|
|  2013 |      1 |    9 |       641 |             900 |       1301 |      1242 |            1530 |       1272 |       HA |      51 |   N384HA |     JFK |   HNL |       640 |      4983 |     9 |       0 | 2013-01-09 09:00:00 |
|  2013 |      6 |   15 |      1432 |            1935 |       1137 |      1607 |            2120 |       1127 |       MQ |    3535 |   N504MQ |     JFK |   CMH |        74 |       483 |    19 |      35 | 2013-06-15 19:00:00 |
|  2013 |      1 |   10 |      1121 |            1635 |       1126 |      1239 |            1810 |       1109 |       MQ |    3695 |   N517MQ |     EWR |   ORD |       111 |       719 |    16 |      35 | 2013-01-10 16:00:00 |
|  2013 |      9 |   20 |      1139 |            1845 |       1014 |      1457 |            2210 |       1007 |       AA |     177 |   N338AA |     JFK |   SFO |       354 |      2586 |    18 |      45 | 2013-09-20 18:00:00 |
```

### Select columns

Lazily convert to `columns` then back to `rows` for columnwise operations.

```jldoctest dplyr
julia> @> flights |>
        columns |>
        Names(:year, :month, :day)(_) |>
        rows |>
        Peek
Showing 4 of 336776 rows
| :year | :month | :day |
| -----:| ------:| ----:|
|  2013 |      1 |    1 |
|  2013 |      1 |    1 |
|  2013 |      1 |    1 |
|  2013 |      1 |    1 |
```

```jldoctest dplyr
julia> @> flights |>
        columns |>
        remove(_, :year, :month, :day) |>
        rows |>
        Peek
Showing 4 of 336776 rows
| :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |
| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|
|       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |
|       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |
|       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |
|       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |
```

```jldoctest dplyr
julia> @> flights |>
        columns |>
        rename(_, tail_num = Name(:tailnum)) |>
        rows |>
        Peek
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour | :tail_num |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:| ---------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |    N14228 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |    N24211 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |    N619AA |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |    N804JB |
```

### Add new columns

```jldoctest dplyr
julia> @> flights |>
        columns |>
        transform(_,
            gain = _.arr_delay .- _.dep_delay,
            speed = _.distance ./ _.air_time * 60
        ) |>
        rows |>
        Peek
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour | :gain |             :speed |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:| -----:| ------------------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |     9 | 370.04405286343615 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |    16 |  374.2731277533039 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |    31 |            408.375 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |   -17 |  516.7213114754098 |
```

## Grouped operations

You can only group sorted data. Each group is a pair, from key (first) to
sub-table (second).

Generator is reexported from Base.

```jldoctest dplyr
julia> using Statistics: mean

julia> @> flights |>
        order(_, Names(:tailnum), (@_ !ismissing(_.tailnum))) |>
        Group(By(_, Names(:tailnum))) |>
        Generator((@_ transform(_.first,
            count = length(_.second),
            dist = (@> _.second |> columns |> _.distance |> skipmissing |> mean),
            delay =(@> _.second |> columns |> _.arr_delay |> skipmissing |> mean)
        )), _) |>
        Peek
Showing at most 4 rows
| :tailnum | :count |             :dist |             :delay |
| --------:| ------:| -----------------:| ------------------:|
|   D942DN |      4 |             854.5 |               31.5 |
|   N0EGMQ |    371 |  676.188679245283 |  9.982954545454545 |
|   N10156 |    153 | 757.9477124183006 | 12.717241379310344 |
|   N102UW |     48 |           535.875 |             2.9375 |
```

# Two table verbs

Follows the tutorial [here](https://cran.r-project.org/web/packages/dplyr/vignettes/two-table.html).

You can only `Join` presorted data. A join will return pairs from an item on the
left (first) to an item on the right (second). `Group` data with repeats.
`flatten` is reexported from Base.

```jldoctest dplyr
julia> flights2 =
        @> flights |>
        columns |>
        Names(:year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier)(_) |>
        rows;

julia> airlines =
        @> "airlines.csv" |>
        CSV.read(_, allowmissing = :auto,) |>
        named_tuple |>
        rows;

julia> Peek(airlines)
Showing 4 of 16 rows
| :carrier |                  :name |
| --------:| ----------------------:|
|       9E |      Endeavor Air Inc. |
|       AA | American Airlines Inc. |
|       AS |   Alaska Airlines Inc. |
|       B6 |        JetBlue Airways |

julia> @> flights2 |>
        order(_, Names(:carrier)) |>
        Group(By(_, Names(:carrier))) |>
        By(_, first) |>
        Join(_, By(airlines, Names(:carrier))) |>
        Generator(pair -> Generator((@_ merge(_, pair.second)), pair.first.second), _) |>
        flatten |>
        Peek
Showing at most 4 rows
| :year | :month | :day | :hour | :origin | :dest | :tailnum | :carrier |             :name |
| -----:| ------:| ----:| -----:| -------:| -----:| --------:| --------:| -----------------:|
|  2013 |      1 |    1 |     8 |     JFK |   MSP |   N915XJ |       9E | Endeavor Air Inc. |
|  2013 |      1 |    1 |    15 |     JFK |   IAD |   N8444F |       9E | Endeavor Air Inc. |
|  2013 |      1 |    1 |    14 |     JFK |   BUF |   N920XJ |       9E | Endeavor Air Inc. |
|  2013 |      1 |    1 |    15 |     JFK |   SYR |   N8409N |       9E | Endeavor Air Inc. |
```

`Join` is full by default; use `Filter` to mimic other kinds of joins.

```jldoctest dplyr
julia> weather =
        @> "weather.csv" |>
        CSV.read(_, allowmissing = :auto) |>
        named_tuple |>
        rows;

julia> Peek(weather)
Showing 4 of 26115 rows
| :origin | :year | :month | :day | :hour | :temp | :dewp | :humid | :wind_dir | :wind_speed | :wind_gust | :precip | :pressure | :visib |          :time_hour |
| -------:| -----:| ------:| ----:| -----:| -----:| -----:| ------:| ---------:| -----------:| ----------:| -------:| ---------:| ------:| -------------------:|
|     EWR |  2013 |      1 |    1 |     1 | 39.02 | 26.06 |  59.37 |       270 |    10.35702 |    missing |     0.0 |    1012.0 |   10.0 | 2013-01-01 01:00:00 |
|     EWR |  2013 |      1 |    1 |     2 | 39.02 | 26.96 |  61.63 |       250 |     8.05546 |    missing |     0.0 |    1012.3 |   10.0 | 2013-01-01 02:00:00 |
|     EWR |  2013 |      1 |    1 |     3 | 39.02 | 28.04 |  64.43 |       240 |     11.5078 |    missing |     0.0 |    1012.5 |   10.0 | 2013-01-01 03:00:00 |
|     EWR |  2013 |      1 |    1 |     4 | 39.92 | 28.04 |  62.21 |       250 |    12.65858 |    missing |     0.0 |    1012.2 |   10.0 | 2013-01-01 04:00:00 |

julia> const selector = Names(:origin, :year, :month, :day, :hour);

julia> @> flights2 |>
        order(_, selector) |>
        Group(By(_, selector)) |>
        By(_, first) |>
        Join(_, By(weather, selector)) |>
        Filter((@_ !ismissing(_.first)), _) |>
        Generator(pair -> Generator((@_ merge(_, pair.second)), pair.first.second), _) |>
        flatten |>
        Peek
Showing at most 4 rows
| :year | :month | :day | :hour | :origin | :dest | :tailnum | :carrier | :temp | :dewp | :humid | :wind_dir | :wind_speed | :wind_gust | :precip | :pressure | :visib |          :time_hour |
| -----:| ------:| ----:| -----:| -------:| -----:| --------:| --------:| -----:| -----:| ------:| ---------:| -----------:| ----------:| -------:| ---------:| ------:| -------------------:|
|  2013 |      1 |    1 |     5 |     EWR |   IAH |   N14228 |       UA | 39.02 | 28.04 |  64.43 |       260 |    12.65858 |    missing |     0.0 |    1011.9 |   10.0 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |     5 |     EWR |   ORD |   N39463 |       UA | 39.02 | 28.04 |  64.43 |       260 |    12.65858 |    missing |     0.0 |    1011.9 |   10.0 | 2013-01-01 05:00:00 |
|  2013 |      1 |    1 |     6 |     EWR |   FLL |   N516JB |       B6 | 37.94 | 28.04 |  67.21 |       240 |     11.5078 |    missing |     0.0 |    1012.4 |   10.0 | 2013-01-01 06:00:00 |
|  2013 |      1 |    1 |     6 |     EWR |   SFO |   N53441 |       UA | 37.94 | 28.04 |  67.21 |       240 |     11.5078 |    missing |     0.0 |    1012.4 |   10.0 | 2013-01-01 06:00:00 |

julia> planes =
        @> "planes.csv" |>
        CSV.read(_, allowmissing = :auto) |>
        named_tuple |>
        rename(_, model_year = Name(:year)) |>
        rows;

julia> Peek(planes)
Showing 4 of 3322 rows
| :tailnum |                   :type |    :manufacturer |    :model | :engines | :seats |  :speed |   :engine | :model_year |
| --------:| -----------------------:| ----------------:| ---------:| --------:| ------:| -------:| ---------:| -----------:|
|   N10156 | Fixed wing multi engine |          EMBRAER | EMB-145XR |        2 |     55 | missing | Turbo-fan |        2004 |
|   N102UW | Fixed wing multi engine | AIRBUS INDUSTRIE |  A320-214 |        2 |    182 | missing | Turbo-fan |        1998 |
|   N103US | Fixed wing multi engine | AIRBUS INDUSTRIE |  A320-214 |        2 |    182 | missing | Turbo-fan |        1999 |
|   N104UW | Fixed wing multi engine | AIRBUS INDUSTRIE |  A320-214 |        2 |    182 | missing | Turbo-fan |        1999 |

julia> @> flights2 |>
            order(_, Names(:tailnum), (@_ !ismissing(_.tailnum))) |>
            Group(By(_, Names(:tailnum))) |>
            By(_, first) |>
            Join(_, By(planes, Names(:tailnum))) |>
            Filter((@_ ismissing(_.second)), _) |>
            Generator((@_ transform(_.first.first,
                n = length(_.first.second)
            )), _) |>
            make_columns |>
            rows |>
            order(_, Names(:n), rev = true) |>
            Peek
Showing 4 of 721 rows
| :tailnum |  :n |
| --------:| ---:|
|   N725MQ | 575 |
|   N722MQ | 513 |
|   N723MQ | 507 |
|   N713MQ | 483 |
```

# Window functions

Follows the tutorial [here](https://cran.r-project.org/web/packages/dplyr/vignettes/window-functions.html).

```jldoctest dplyr
julia> batting =
        @> "batting.csv" |>
        CSV.read(_, allowmissing = :auto) |>
        named_tuple |>
        rows;

julia> Peek(batting)
Showing 4 of 19404 rows
| :playerID | :yearID | :teamID |  :G | :AB |  :R |  :H |
| ---------:| -------:| -------:| ---:| ---:| ---:| ---:|
| aaronha01 |    1954 |     ML1 | 122 | 468 |  58 | 131 |
| aaronha01 |    1955 |     ML1 | 153 | 602 | 105 | 189 |
| aaronha01 |    1956 |     ML1 | 153 | 609 | 106 | 200 |
| aaronha01 |    1957 |     ML1 | 151 | 615 | 118 | 198 |

julia> players =
        @> batting |>
        Group(By(_, Names(:playerID)));

julia> @> players |>
        Generator((@_ @> order(_.second, Names(:H)) |> view(_, 1:2)), _) |>
        flatten |>
        Filter((@_ _.H > 0), _) |>
        Peek
Showing at most 4 rows
| :playerID | :yearID | :teamID |  :G | :AB |  :R |  :H |
| ---------:| -------:| -------:| ---:| ---:| ---:| ---:|
| aaronha01 |    1976 |     ML4 |  85 | 271 |  22 |  62 |
| aaronha01 |    1974 |     ATL | 112 | 340 |  47 |  91 |
| abreubo01 |    1996 |     HOU |  15 |  22 |   1 |   5 |
| abreubo01 |    2012 |     LAA |   8 |  24 |   1 |   5 |

julia> using StatsBase: ordinalrank

julia> @> players |>
        Generator((@_ @> columns(_.second) |>
            transform(_, G_rank = ordinalrank(_.G)) |>
            rows
        ), _) |>
        flatten |>
        Peek
Showing at most 4 rows
| :playerID | :yearID | :teamID |  :G | :AB |  :R |  :H | :G_rank |
| ---------:| -------:| -------:| ---:| ---:| ---:| ---:| -------:|
| aaronha01 |    1954 |     ML1 | 122 | 468 |  58 | 131 |       4 |
| aaronha01 |    1955 |     ML1 | 153 | 602 | 105 | 189 |      13 |
| aaronha01 |    1956 |     ML1 | 153 | 609 | 106 | 200 |      14 |
| aaronha01 |    1957 |     ML1 | 151 | 615 | 118 | 198 |      12 |
```

# Programming with LightQuery

Follows the tutorial [here](https://cran.r-project.org/web/packages/dplyr/vignettes/programming.html).

Be sure to `@inline` if you rely on constant propagation.

```jldoctest dplyr
julia> df = (
            g1 = [1, 1, 2, 2, 2],
            g2 = [1, 2, 1, 2, 1],
            a = 1:5,
            b = 1:5
        ) |>
        rows;

julia> Peek(df)
Showing 4 of 5 rows
| :g1 | :g2 |  :a |  :b |
| ---:| ---:| ---:| ---:|
|   1 |   1 |   1 |   1 |
|   1 |   2 |   2 |   2 |
|   2 |   1 |   3 |   3 |
|   2 |   2 |   4 |   4 |

julia> my_summarize_(df, group_var) =
        @> df |>
        order(_, group_var) |>
        Group(By(_, group_var)) |>
        Generator((@_ transform(_.first,
            a = sum(columns(_.second).a)
        )), _) |>
        make_columns |>
        rows;

julia> Peek(my_summarize_(df, Names(:g1)))
| :g1 |  :a |
| ---:| ---:|
|   1 |   3 |
|   2 |  12 |

julia> Peek(my_summarize_(df, Names(:g2)))
| :g2 |  :a |
| ---:| ---:|
|   1 |   9 |
|   2 |   6 |

julia> @inline my_summarize(df, group_vars...) =
        my_summarize_(df, Names(group_vars...));

julia> Peek(my_summarize(df, :g1))
| :g1 |  :a |
| ---:| ---:|
|   1 |   3 |
|   2 |  12 |
```

# Index

```@index
```

## Autodocs

```@autodocs
Modules = [LightQuery]
```
