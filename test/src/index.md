# LightQuery.jl

```@index
```


```@autodocs
Modules = [LightQuery]
```

# Tutorial

For an example of how to use this package, see the demo below, which follows the
example [here](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html).

A copy of the flights data is included in the test folder of this package. I've
reexported CSV from the CSV package for convenient IO. The data comes in as a
data frame, but you can easily convert most objects to named tuples using
`named_tuple`. I recollect to remove extra missing annotations unhelpfully
provided by CSV.

```jldoctest dplyr
julia> using LightQuery

julia> flight_columns =
        @> CSV.read("flights.csv", missingstring = "NA") |>
        named_tuple |>
        map(x -> collect(over(x, identity)), _);
```

As a named tuple, the data will be in a column-wise form; lazily convert it to
`rows`.

```jldoctest dplyr
julia> flights = rows(flight_columns)
Showing 7 of 19 columns
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |
```

You can lazily filter data with `when`.

```jldoctest dplyr
julia> using LightQuery

julia> @> flights |>
        when(_, @_ _.month == 1 && _.day == 1)
Showing 7 of 19 columns
Showing at most 4 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |
```

You might find it more efficient to do this columns-wise:

```jldoctest dplyr
julia> using LightQuery

julia> @> flight_columns |>
        (_.month .== 1) .& (_.day .== 1) |>
        view(flights, _)
Showing 7 of 19 columns
Showing 4 of 842 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |
```

You can `order` the flights, using `Names` to select columns.

```jldoctest dplyr
julia> using MappedArrays: mappedarray

julia> get_date = Names(:year, :month, :day)
Names{(:year, :month, :day)}()

julia> by_date =
        @> flights |>
        order(_, get_date)
Showing 7 of 19 columns
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |
```

You can also pass in keyword arguments to `sort!` via `order`, like
`rev = true`. Note also that `arr_delay` includes missing data. For performance,
I'm adding a condition to remove the missing data. This will be a common
pattern.

```jldoctest dplyr
julia> @> flights |>
        order(_, Names(:arr_delay), (@_ !ismissing(_.arr_delay)), rev = true)
Showing 7 of 19 columns
Showing 4 of 327346 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      1 |    9 |       641 |             900 |       1301 |      1242 |
|  2013 |      6 |   15 |      1432 |            1935 |       1137 |      1607 |
|  2013 |      1 |   10 |      1121 |            1635 |       1126 |      1239 |
|  2013 |      9 |   20 |      1139 |            1845 |       1014 |      1457 |
```

In the original column-wise form, you can select with `Names`. Then,
use `rows` again to print.

```jldoctest dplyr
julia> get_date(flight_columns) |>
          rows
Showing 4 of 336776 rows
| :year | :month | :day |
| -----:| ------:| ----:|
|  2013 |      1 |    1 |
|  2013 |      1 |    1 |
|  2013 |      1 |    1 |
|  2013 |      1 |    1 |
```

You can also remove columns in the column-wise form.

```jldoctest dplyr
julia> @> flight_columns |>
        remove(_, :year, :month, :day) |>
        rows
Showing 7 of 16 columns
Showing 4 of 336776 rows
| :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier |
| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:|
|       517 |             515 |          2 |       830 |             819 |         11 |       UA |
|       533 |             529 |          4 |       850 |             830 |         20 |       UA |
|       542 |             540 |          2 |       923 |             850 |         33 |       AA |
|       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |
```

You can also rename columns. Because constants (currently) do not propagate
through keyword arguments in Julia, it's smart to wrap column names with
`Name`.

```jldoctest dplyr
julia> @> flight_columns |>
        rename(_, tail_num = Name(:tailnum)) |>
        rows
Showing 7 of 19 columns
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |
```

You can add new columns with transform. If you want to refer to previous
columns, you'll have to transform twice. You can do this row-wise. Note that
I've added a second `over` simply to specify the names of the items. This will
be a common pattern for when inference can't keep track of names.

```jldoctest dplyr
julia> @> flights |>
        over(_, @_ @> transform(_,
            gain = _.arr_delay - _.dep_delay,
            speed = _.distance / _.air_time * 60
        ) |> transform(_,
            gain_per_hour = _.gain ./ (_.air_time / 60)
        )) |>
        over(_, Names(propertynames(flight_columns)..., :gain, :speed,
            :gain_per_hour))
Showing 7 of 22 columns
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |
```

You can also do the same thing column-wise:

```jldoctest dplyr
julia> @> flight_columns |>
        transform(_,
            gain = _.arr_delay .- _.dep_delay,
            speed = _.distance ./ _.air_time .* 60
        ) |>
        transform(_,
            gain_per_hour = _.gain ./ (_.air_time / 60)
        ) |>
        rows
Showing 7 of 22 columns
Showing 4 of 336776 rows
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |
|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |
|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |
|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |
```

You can't summarize ungrouped data, but you can just directly access columns:

```jldoctest dplyr
julia> using Statistics: mean;

julia> mean(skipmissing(flight_columns.dep_delay))
12.639070257304708
```

I don't provide a export a sample function here, but StatsBase does.

`Group`ing here works differently than in dplyr:

- You can only `Group` sorted data. To let Julia know that the data has been sorted, you need to explicitly wrap the data with `By`.
- Groups return a pair, key => sub-data-frame. So:

```jldoctest dplyr
julia> by_tailnum =
        @> flights |>
        order(_, Names(:tailnum), (@_ !ismissing(_.tailnum))) |>
        Group(By(_, Names(:tailnum)));

julia> first(by_tailnum)
(tailnum = "D942DN",) => Showing 7 of 19 columns
| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |
| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|
|  2013 |      2 |   11 |      1508 |            1400 |         68 |      1807 |
|  2013 |      3 |   23 |      1340 |            1300 |         40 |      1638 |
|  2013 |      3 |   24 |       859 |             835 |         24 |      1142 |
|  2013 |      7 |    5 |      1253 |            1259 |         -6 |      1518 |
```

You can play around with the pair structure of groups to coerce it to the shape
you want. Notice that I'm `collect`ing after the `Group` (for performance). I'm
also explicitly calling `Peek` here; Julia can only guess that you want a peek
if `over` was used with a `Names` object.

```jldoctest dplyr
julia> @> by_tailnum |>
        collect |>
        over(_, @_ transform(_.first,
            count = length(_.second),
            distance = columns(_.second).distance |> mean,
            delay = columns(_.second).arr_delay |> skipmissing |> mean
        )) |>
        Peek
Showing 4 of 4043 rows
| :tailnum | :count |         :distance |             :delay |
| --------:| ------:| -----------------:| ------------------:|
|   D942DN |      4 |             854.5 |               31.5 |
|   N0EGMQ |    371 |  676.188679245283 |  9.982954545454545 |
|   N10156 |    153 | 757.9477124183006 | 12.717241379310344 |
|   N102UW |     48 |           535.875 |             2.9375 |
```

For the n-distinct example, I've switched things around to be just a smidge
more efficient. This example shows how calling `make_columns` and then `rows` is
sometimes necessary to trigger eager evaluation. I've also defined a
`count_flights` function because we'll be using it again.

```jldoctest dplyr
julia> count_flights(x) = over(x, @_ transform(_.first,
            flights = length(_.second)
        ));

julia> @> flights |>
        order(_, Names(:dest, :tailnum), (@_ !ismissing(_.tailnum))) |>
        Group(By(_, Names(:dest, :tailnum))) |>
        collect |>
        count_flights |>
        make_columns |>
        rows |>
        Group(By(_, Names(:dest))) |>
        over(_, @_ transform(_.first,
            planes = length(_.second),
            flights = sum(columns(_.second).flights)
        )) |>
        Peek
Showing at most 4 rows
| :dest | :planes | :flights |
| -----:| -------:| --------:|
|   ABQ |     108 |      254 |
|   ACK |      58 |      265 |
|   ALB |     172 |      439 |
|   ANC |       6 |        8 |
```

Of course, you can group repeatedly. You don't have to reorder each time if you
do this.

```jldoctest dplyr
julia> grouped_by_date =
        @> by_date |>
        Group(By(_, get_date)) |>
        collect;

julia> per_day =
        @> grouped_by_date |>
        count_flights |>
        make_columns |>
        rows
Showing 4 of 365 rows
| :year | :month | :day | :flights |
| -----:| ------:| ----:| --------:|
|  2013 |      1 |    1 |      842 |
|  2013 |      1 |    2 |      943 |
|  2013 |      1 |    3 |      914 |
|  2013 |      1 |    4 |      915 |

julia> sum_flights(x) = over(x, @_ transform(_.first,
            flights = sum(columns(_.second).flights)
        ));

julia> per_month =
        @> per_day |>
        Group(By(_, Names(:year, :month))) |>
        collect |>
        sum_flights |>
        make_columns |>
        rows
Showing 4 of 12 rows
| :year | :month | :flights |
| -----:| ------:| --------:|
|  2013 |      1 |    27004 |
|  2013 |      2 |    24951 |
|  2013 |      3 |    28834 |
|  2013 |      4 |    28330 |

julia> @> per_month |>
          Group(By(_, Names(:year))) |>
          sum_flights |>
          Peek
Showing at most 4 rows
| :year | :flights |
| -----:| --------:|
|  2013 |   336776 |
```

Here's the example in the dplyr docs for piping:

```jldoctest dplyr
julia> @> grouped_by_date |>
        over(_, @_ transform(_.first,
            arr = columns(_.second).arr_delay |> skipmissing |> mean,
            dep = columns(_.second).dep_delay |> skipmissing |> mean
        )) |>
        when(_, @_ _.arr > 30 || _.dep > 30) |>
        over(_, Names(:year, :month, :day, :arr, :dep))
Showing at most 4 rows
| :year | :month | :day |               :arr |               :dep |
| -----:| ------:| ----:| ------------------:| ------------------:|
|  2013 |      1 |   16 |  34.24736225087925 | 24.612865497076022 |
|  2013 |      1 |   31 | 32.602853745541026 | 28.658362989323845 |
|  2013 |      2 |   11 |  36.29009433962264 |  39.07359813084112 |
|  2013 |      2 |   27 |  31.25249169435216 |  37.76327433628319 |
```

# Two table verbs

I'm following the example [here](https://cran.r-project.org/web/packages/dplyr/vignettes/two-table.html).

Again, for inference reasons, natural joins won't work. I only provide one join
at the moment, but it's super efficient. Let's start by reading in airlines and
letting julia know that it's already sorted by `:carrier`.

```jldoctest dplyr
julia> airlines =
        @> CSV.read("airlines.csv", missingstring = "NA") |>
        named_tuple |>
        map(x -> collect(over(x, identity)), _) |>
        rows |>
        By(_, Names(:carrier));
```

If we want to join this data into the flights data, here's what we do.
`LeftJoin` requires not only presorted but **unique** keys. Of course,
there are multiple flights from the same airline, so we need to group first.
Then, we tell Julia that the groups are themselves sorted (by the first item,
the key). Finally we can join in the airline data. But the results are a bit
tricky. Let's take a look at the first item. Just like the dplyr manual, I'm
only using a few of the columns from `flights` for demonstration.

```jldoctest dplyr
julia> flight2_columns =
        @> flight_columns |>
        Names(:year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier)(_);

julia> flights2 = rows(flight2_columns)
Showing 7 of 8 columns
Showing 4 of 336776 rows
| :year | :month | :day | :hour | :origin | :dest | :tailnum |
| -----:| ------:| ----:| -----:| -------:| -----:| --------:|
|  2013 |      1 |    1 |     5 |     EWR |   IAH |   N14228 |
|  2013 |      1 |    1 |     5 |     LGA |   IAH |   N24211 |
|  2013 |      1 |    1 |     5 |     JFK |   MIA |   N619AA |
|  2013 |      1 |    1 |     5 |     JFK |   BQN |   N804JB |

julia> airline_join =
        @> flights2 |>
        order(_, Names(:carrier)) |>
        Group(By(_, Names(:carrier))) |>
        By(_, first) |>
        LeftJoin(_, airlines);

julia> first(airline_join)
((carrier = "9E",)=>Showing 7 of 8 columns
Showing 4 of 18460 rows
| :year | :month | :day | :hour | :origin | :dest | :tailnum |
| -----:| ------:| ----:| -----:| -------:| -----:| --------:|
|  2013 |      1 |    1 |     8 |     JFK |   MSP |   N915XJ |
|  2013 |      1 |    1 |    15 |     JFK |   IAD |   N8444F |
|  2013 |      1 |    1 |    14 |     JFK |   BUF |   N920XJ |
|  2013 |      1 |    1 |    15 |     JFK |   SYR |   N8409N |
) => (carrier = "9E", name = "Endeavor Air Inc.")
```

We end up getting a group and subframe on the left, and a row on the right.

If you want to collect your results into a flat new dataframe, you need to do a
bit of surgery, including making use of `flatten` (which I reexport from Base).
We also need to make a fake row to insert on the right in case we can't find a
match.

```jldoctest dplyr
julia> @> airline_join |>
        over(_, @_ over(_.first.second, x -> merge(x, _.second))) |>
        flatten |>
        over(_, Names(:year, :month, :day, :hour, :origin, :dest, :tailnum,
            :carrier, :name))
Showing 7 of 9 columns
Showing at most 4 rows
| :year | :month | :day | :hour | :origin | :dest | :tailnum |
| -----:| ------:| ----:| -----:| -------:| -----:| --------:|
|  2013 |      1 |    1 |     8 |     JFK |   MSP |   N915XJ |
|  2013 |      1 |    1 |    15 |     JFK |   IAD |   N8444F |
|  2013 |      1 |    1 |    14 |     JFK |   BUF |   N920XJ |
|  2013 |      1 |    1 |    15 |     JFK |   SYR |   N8409N |
```

Let's keep going in the examples. I'm going to read in the weather data, and let
Julia know that it has already been sorted.

```jldoctest dplyr
julia> weather_columns =
        @> CSV.read( "weather.csv", missingstring = "NA") |>
        named_tuple |>
        map(x -> collect(over(x, identity)), _);

julia> weather =
        @> weather_columns |>
        rows |>
        By(_, Names(:origin, :year, :month, :day, :hour));
```

Unfortunately, we have to deal with another problem: there's gaps in the weather
data. We need to make a missing row of data. I'm also going to use `union` to
get all the names together.

```jldoctest dplyr
julia> const missing_weather =
        @> weather_columns |>
        remove(_, :origin, :year, :month, :day, :hour) |>
        map(x -> missing, _);

julia> weather_join =
        @> flights2 |>
        order(_, Names(:origin, :year, :month, :day, :hour)) |>
        Group(By(_, Names(:origin, :year, :month, :day, :hour))) |>
        By(_, first) |>
        LeftJoin(_, weather);

julia> flight2_and_weather_names = Names(union(
            propertynames(flight2_columns),
            propertynames(weather_columns)
        )...);

julia> @> weather_join |>
        over(_, @_ over(_.first.second, x -> merge(x, coalesce(_.second, missing_weather)))) |>
        flatten |>
        over(_, flight2_and_weather_names)
Showing 7 of 18 columns
Showing at most 4 rows
| :year | :month | :day | :hour | :origin | :dest | :tailnum |
| -----:| ------:| ----:| -----:| -------:| -----:| --------:|
|  2013 |      1 |    1 |     5 |     EWR |   IAH |   N14228 |
|  2013 |      1 |    1 |     5 |     EWR |   ORD |   N39463 |
|  2013 |      1 |    1 |     6 |     EWR |   FLL |   N516JB |
|  2013 |      1 |    1 |     6 |     EWR |   SFO |   N53441 |
```

Of course, if you wanted, you could just remove the rows with missing weather
data, essentially doing an inner join:

```jldoctest dplyr
julia> @> weather_join |>
        when(_, @_ _.second !== missing) |>
        over(_, @_ over(_.first.second, x -> merge(x, missing_weather))) |>
        flatten |>
        over(_, flight2_and_weather_names)
Showing 7 of 18 columns
Showing at most 4 rows
| :year | :month | :day | :hour | :origin | :dest | :tailnum |
| -----:| ------:| ----:| -----:| -------:| -----:| --------:|
|  2013 |      1 |    1 |     5 |     EWR |   IAH |   N14228 |
|  2013 |      1 |    1 |     5 |     EWR |   ORD |   N39463 |
|  2013 |      1 |    1 |     6 |     EWR |   FLL |   N516JB |
|  2013 |      1 |    1 |     6 |     EWR |   SFO |   N53441 |
```
