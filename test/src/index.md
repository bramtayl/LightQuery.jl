# LightQuery.jl

```@index
```

```@autodocs
Modules = [LightQuery]
```

# Tutorial

I started following the tutorial here
[here](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html), but
got side-tracked by a data cleaning task. You get to see the results, hooray.
I've included the flights data in test folder of this package.

I've reexported CSV from the CSV package for convenient IO. We can process the
data as we are reading in the file itself! This is because CSV.File returns an iterator.

I do a lot of steps here so let's break them down:

First, I bring in some dates functions, and make them work with missing data.

In the `CSV.File` step, I mark that missing is denoted by "NA" in the file. I also
specify that I want strings to come in as categorical data.

Then I transform each row. First, I convert each row to a named tuple. Then, I combine
the scheduled arrival and departure times into a single date-time. The bit at the end
about `divrem` basically means that in a number like `530`, hours are in the hundreds
place and minutes are in the rest (e.g. 5:30). Then I rename to get rid of
abbreviations (you'll figure out if you haven't already that I'm a big fan of whole
words). Then, I select just the columns we want. I've taken the liberty of ignoring
calculated data, that is, data that we can calculate later on. Also, mapping a
`Names` object with `over` helps Julia out. Julia can't infer the names of the rows
without this step. This is the because we have two or more type-unstable
columns (e.g. departure delay and arrival delay both might be missing).

```jldoctest dplyr
julia> using LightQuery

julia> using Dates: DateTime

julia> import Dates: Minute

julia> Minute(::Missing) = missing;

julia> using Unitful: mi

julia> flight_columns =
            @> CSV.File("flights.csv", missingstring = "NA", categorical = true) |>
            over(_, @_ @> named_tuple(_) |>
                transform(_,
                    departure_time = DateTime(_.year, _.month, _.day,
                        divrem(_.sched_dep_time, 100)...),
                    departure_delay = Minute(_.dep_delay),
                    arrival_time = DateTime(_.year, _.month, _.day,
                        divrem(_.sched_arr_time, 100)...),
                    arrival_delay = Minute(_.arr_delay),
                    distance = _.distance * mi
                ) |>
                rename(_,
                    tail_number = Name(:tailnum),
                    destination = Name(:dest)
                )
            ) |>
            over(_, Names(:departure_time, :departure_delay, :arrival_time,
                :arrival_delay, :carrier, :flight, :tail_number, :origin,
                :destination, :distance)
            ) |>
            make_columns;
```

Now that we have our data into Julia, let's have a look see. We'll start by converting
it back to columns, and then taking a `Peek`. I've taken the liberty of increasing the
number of visible columns to 10. The default max `Peek` size is 7 columns by 4 rows.

```jldoctest dplyr
julia> flights = rows(flight_columns);

julia> Peek(flights, max_columns = 10)
Showing 4 of 336776 rows
|     :departure_time | :departure_delay |       :arrival_time | :arrival_delay | :carrier | :flight | :tail_number | :origin | :destination | :distance |
| -------------------:| ----------------:| -------------------:| --------------:| --------:| -------:| ------------:| -------:| ------------:| ---------:|
| 2013-01-01T05:15:00 |        2 minutes | 2013-01-01T08:19:00 |     11 minutes |       UA |    1545 |       N14228 |     EWR |          IAH |   1400 mi |
| 2013-01-01T05:29:00 |        4 minutes | 2013-01-01T08:30:00 |     20 minutes |       UA |    1714 |       N24211 |     LGA |          IAH |   1416 mi |
| 2013-01-01T05:40:00 |        2 minutes | 2013-01-01T08:50:00 |     33 minutes |       AA |    1141 |       N619AA |     JFK |          MIA |   1089 mi |
| 2013-01-01T05:45:00 |        -1 minute | 2013-01-01T10:22:00 |    -18 minutes |       B6 |     725 |       N804JB |     JFK |          BQN |   1576 mi |
```

There's one more cleaning step we can make. Note that distance is a calculated
field. That is, the distance between two locations is always going to be the
same. How can we get a clean dataset which only contains the distances between
two airports?

Let's start out by grouping our data by path. Before you group, you *MUST* sort.
Otherwise, you will get incorrect results. Of course, if we have pre-sorted data, no need.

```jldoctest dplyr
julia> by_path =
            @> flights |>
            order(_, Names(:origin, :destination)) |>
            Group(By(_, Names(:origin, :destination))) |>
            collect;
```

I encourage you to collect after Grouping. This will not use much additional
data, it will only store the keys locations of the groups. Grouping is a little
different from dplyr; each group is a pair from key to sub-data-frame:

```jldoctest dplyr
julia> first_group = first(by_path);

julia> first_group.first
(origin = CategoricalArrays.CategoricalString{UInt32} "EWR", destination = CategoricalArrays.CategoricalString{UInt32} "ALB")

julia> Peek(first_group.second, max_columns = 10)
Showing 4 of 439 rows
|     :departure_time | :departure_delay |       :arrival_time | :arrival_delay | :carrier | :flight | :tail_number | :origin | :destination | :distance |
| -------------------:| ----------------:| -------------------:| --------------:| --------:| -------:| ------------:| -------:| ------------:| ---------:|
| 2013-01-01T13:17:00 |       -2 minutes | 2013-01-01T14:23:00 |    -10 minutes |       EV |    4112 |       N13538 |     EWR |          ALB |    143 mi |
| 2013-01-01T16:21:00 |       34 minutes | 2013-01-01T17:24:00 |     40 minutes |       EV |    3260 |       N19554 |     EWR |          ALB |    143 mi |
| 2013-01-01T20:04:00 |       52 minutes | 2013-01-01T21:12:00 |     44 minutes |       EV |    4170 |       N12540 |     EWR |          ALB |    143 mi |
| 2013-01-02T13:27:00 |        5 minutes | 2013-01-02T14:33:00 |    -14 minutes |       EV |    4316 |       N14153 |     EWR |          ALB |    143 mi |
```

So there are 439 flights between Newark (EWR lol) and Albany. The distances are the same, so we really only need the first one. So here's what we do:
Calling `make_columns` and then `rows` will collect out data (the smart way).

```jldoctest dplyr
julia> paths =
        @> by_path |>
        over(_, @_ first(_.second)) |>
        over(_, Names(:origin, :destination, :distance)) |>
        make_columns |>
        rows;

julia> Peek(paths)
Showing 4 of 224 rows
| :origin | :destination | :distance |
| -------:| ------------:| ---------:|
|     EWR |          ALB |    143 mi |
|     EWR |          ANC |   3370 mi |
|     EWR |          ATL |    746 mi |
|     EWR |          AUS |   1504 mi |
```

Ok, now let's do the whole damn thing in reverse, just for fun. How? We need to
join back into the original data. Our data that was grouped by path is sorted by
the first item, and our path data is sorted by `:origin` and `:destination`.
Note there are no repeats: we've pregrouped our data. This is important for a
left join.

```jldoctest dplyr
julia> joined = LeftJoin(
            By(by_path, first),
            By(paths, Names(:origin, :destination))
        );
```

A join will a row on the left and a row on the right. And the row on the left
is a group, so it's also got a key and a value. Oy.

```jldoctest dplyr
julia> pair = first(joined);

julia> pair.first.first
(origin = CategoricalArrays.CategoricalString{UInt32} "EWR", destination = CategoricalArrays.CategoricalString{UInt32} "ALB")

julia> Peek(pair.first.second, max_columns = 10)
Showing 4 of 439 rows
|     :departure_time | :departure_delay |       :arrival_time | :arrival_delay | :carrier | :flight | :tail_number | :origin | :destination | :distance |
| -------------------:| ----------------:| -------------------:| --------------:| --------:| -------:| ------------:| -------:| ------------:| ---------:|
| 2013-01-01T13:17:00 |       -2 minutes | 2013-01-01T14:23:00 |    -10 minutes |       EV |    4112 |       N13538 |     EWR |          ALB |    143 mi |
| 2013-01-01T16:21:00 |       34 minutes | 2013-01-01T17:24:00 |     40 minutes |       EV |    3260 |       N19554 |     EWR |          ALB |    143 mi |
| 2013-01-01T20:04:00 |       52 minutes | 2013-01-01T21:12:00 |     44 minutes |       EV |    4170 |       N12540 |     EWR |          ALB |    143 mi |
| 2013-01-02T13:27:00 |        5 minutes | 2013-01-02T14:33:00 |    -14 minutes |       EV |    4316 |       N14153 |     EWR |          ALB |    143 mi |

julia> pair.second
(origin = CategoricalArrays.CategoricalString{UInt32} "EWR", destination = CategoricalArrays.CategoricalString{UInt32} "ALB", distance = 143 mi)
```

How are we gonna get this all back into a flat data-frame? We need to make use of flatten (which is reexported from Base).

```
julia> @> joined |>
        over(_, pair -> over(pair.first.second, @_ transform(_, distance_again = pair.second.distance))) |>
        flatten |>
        Peek(_, max_columns = 11)

Showing at most 4 rows
|     :departure_time | :departure_delay |       :arrival_time | :arrival_delay | :carrier | :flight | :tail_number | :origin | :destination | :distance | :distance_again |
| -------------------:| ----------------:| -------------------:| --------------:| --------:| -------:| ------------:| -------:| ------------:| ---------:| ---------------:|
| 2013-01-01T13:17:00 |       -2 minutes | 2013-01-01T14:23:00 |    -10 minutes |       EV |    4112 |       N13538 |     EWR |          ALB |    143 mi |          143 mi |
| 2013-01-01T16:21:00 |       34 minutes | 2013-01-01T17:24:00 |     40 minutes |       EV |    3260 |       N19554 |     EWR |          ALB |    143 mi |          143 mi |
| 2013-01-01T20:04:00 |       52 minutes | 2013-01-01T21:12:00 |     44 minutes |       EV |    4170 |       N12540 |     EWR |          ALB |    143 mi |          143 mi |
| 2013-01-02T13:27:00 |        5 minutes | 2013-01-02T14:33:00 |    -14 minutes |       EV |    4316 |       N14153 |     EWR |          ALB |    143 mi |          143 mi |
```

Look! The distances match. Hooray!

Are you exhaused? I'll admit, I am. Hope you learned something.
