# Tutorial

I'm going to use the flights data from the [dplyr tutorial](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html). This data is in the test folder of this package; I created it with the following R code:

```R
library(nycflights13)
setwd("C:/Users/hp/.julia/dev/LightQuery/test")
write.csv(airports, "airports.csv", na = "", row.names = FALSE)
write.csv(flights, "flights.csv", na = "", row.names = FALSE)
```

Let's import the tools we need. I'm pulling in from tools from `Dates`, `TimeZones`, and `Unitful`, and modifying them to work with missing data.

```jldoctest dplyr
julia> using LightQuery

julia> using Dates: DateTime, Day, Minute

julia> Minute(::Missing) = missing;

julia> using Unitful: mi, °, ft

julia> using TimeZones: TimeZone, VariableTimeZone, ZonedDateTime

julia> TimeZone_or_missing(time_zone) =
            try
                TimeZone(time_zone)
            catch an_error
                if isa(an_error, ArgumentError)
                    missing
                else
                    rethrow(an_error)
                end
            end;

julia> ZonedDateTime(::DateTime, ::Missing) = missing;
```

I re-export [`CSV`](http://juliadata.github.io/CSV.jl/stable/) for input-output. See the documentation there for information about [`CSV.File`](http://juliadata.github.io/CSV.jl/stable/#CSV.File).

```jldoctest dplyr
julia> airports_file = CSV.File("airports.csv",
            allowmissing = :auto
        )
CSV.File("airports.csv", rows=1458):
Tables.Schema:
 :faa    String
 :name   String
 :lat    Float64
 :lon    Float64
 :alt    Int64
 :tz     Int64
 :dst    String
 :tzone  String
```

Let's take a look at the first row. Use [`named_tuple`](@ref) to coerce a `CSV.Row` to a `NamedTuple`.

```jldoctest dplyr
julia> airport =
        airports_file |>
        first |>
        named_tuple
(faa = "04G", name = "Lansdowne Airport", lat = 41.1304722, lon = -80.6195833, alt = 1044, tz = -5, dst = "A", tzone = "America/New_York")
```

As a start, I want to rename so that I understand what the columns mean. When you [`rename`](@ref), names need to be wrapped with [`Name`](@ref). Here, I use the chaining macro [`@>`](@ref) to chain several calls together.

```jldoctest dplyr
julia> airport =
        @> airport |>
        rename(_,
            airport_code = Name(:faa),
            latitude = Name(:lat),
            longitude = Name(:lon),
            altitude = Name(:alt),
            time_zone_offset = Name(:tz),
            daylight_savings = Name(:dst),
            time_zone = Name(:tzone)
        )
(name = "Lansdowne Airport", airport_code = "04G", latitude = 41.1304722, longitude = -80.6195833, altitude = 1044, time_zone_offset = -5, daylight_savings = "A", time_zone = "America/New_York")
```

Let's create a proper `TimeZone`.

```jldoctest dplyr
julia> airport =
        @> airport |>
        transform(_,
            time_zone = TimeZone_or_missing(_.time_zone)
        )
(name = "Lansdowne Airport", airport_code = "04G", latitude = 41.1304722, longitude = -80.6195833, altitude = 1044, time_zone_offset = -5, daylight_savings = "A", time_zone = America/New_York (UTC-5/UTC-4))
```

Now that we have a true timezone, we can [`remove`](@ref) all data that is contingent on timezone.

```jldoctest dplyr
julia> airport =
        @> airport |>
        remove(_,
            :time_zone_offset,
            :daylight_savings
        )
(name = "Lansdowne Airport", airport_code = "04G", latitude = 41.1304722, longitude = -80.6195833, altitude = 1044, time_zone = America/New_York (UTC-5/UTC-4))
```

Let's also add proper units to our variables.

```jldoctest dplyr
julia> airport =
        @> airport |>
        transform(_,
            latitude = _.latitude * °,
            longitude = _.longitude * °,
            altitude = _.altitude * ft
        )
(name = "Lansdowne Airport", airport_code = "04G", latitude = 41.1304722°, longitude = -80.6195833°, altitude = 1044 ft, time_zone = America/New_York (UTC-5/UTC-4))
```

Let's put it all together. Note I'm adding a `@noinline` annotation to make use
of the [function barrier trick](https://docs.julialang.org/en/v1/manual/performance-tips/index.html#kernel-functions-1).

```jldoctest dplyr
julia> @noinline function process_airport(airport_row)
            @> airport_row |>
            rename(_,
                airport_code = Name(:faa),
                latitude = Name(:lat),
                longitude = Name(:lon),
                altitude = Name(:alt),
                time_zone_offset = Name(:tz),
                daylight_savings = Name(:dst),
                time_zone = Name(:tzone)
            ) |>
            transform(_,
                time_zone = TimeZone_or_missing(_.time_zone),
                latitude = _.latitude * °,
                longitude = _.longitude * °,
                altitude = _.altitude * ft
            ) |>
            remove(_,
                :time_zone_offset,
                :daylight_savings
            )
        end;
```

I use [`over`](@ref) to lazily `map`.

```jldoctest dplyr
julia> airports =
        @> airports_file |>
        over(_, named_tuple) |>
        over(_, process_airport);
```

When it comes time to collect, I'm calling [`make_columns`](@ref) then [`rows`](@ref). It makes sense to store this data column-wise. This is because there are multiple columns that might contain missing data.

```jldoctest dplyr
julia> airports =
        airports |>
        make_columns |>
        rows;
```

We can use [`Peek`](@ref) to get a look at the data.

```jldoctest dplyr
julia> Peek(airports)
Showing 4 of 1458 rows
|                         :name | :airport_code |   :latitude |   :longitude | :altitude |                     :time_zone |
| -----------------------------:| -------------:| -----------:| ------------:| ---------:| ------------------------------:|
|             Lansdowne Airport |           04G | 41.1304722° | -80.6195833° |   1044 ft | America/New_York (UTC-5/UTC-4) |
| Moton Field Municipal Airport |           06A | 32.4605722° | -85.6800278° |    264 ft |  America/Chicago (UTC-6/UTC-5) |
|           Schaumburg Regional |           06C | 41.9893408° | -88.1012428° |    801 ft |  America/Chicago (UTC-6/UTC-5) |
|               Randall Airport |           06N |  41.431912° | -74.3915611° |    523 ft | America/New_York (UTC-5/UTC-4) |
```

I'll also make sure the airports are [`indexed`](@ref) by their code so we can access them quickly.

```jldoctest dplyr
julia> airports =
        @> airports |>
        indexed(_, Name(:airport_code));

julia> airports["JFK"]
(name = "John F Kennedy Intl", airport_code = "JFK", latitude = 40.639751°, longitude = -73.778925°, altitude = 13 ft, time_zone = America/New_York (UTC-5/UTC-4))
```

That was just the warm-up. Now let's get started working on the flights data.

```jldoctest dplyr
julia> flights_file = CSV.File("flights.csv", allowmissing = :auto)
CSV.File("flights.csv", rows=336776):
Tables.Schema:
 :year            Int64
 :month           Int64
 :day             Int64
 :dep_time        Union{Missing, Int64}
 :sched_dep_time  Int64
 :dep_delay       Union{Missing, Int64}
 :arr_time        Union{Missing, Int64}
 :sched_arr_time  Int64
 :arr_delay       Union{Missing, Int64}
 :carrier         String
 :flight          Int64
 :tailnum         Union{Missing, String}
 :origin          String
 :dest            String
 :air_time        Union{Missing, Int64}
 :distance        Int64
 :hour            Int64
 :minute          Int64
 :time_hour       String

julia> flight =
        @> flights_file |>
        first |>
        named_tuple |>
        rename(_,
            departure_time = Name(:dep_time),
            scheduled_departure_time = Name(:sched_dep_time),
            departure_delay = Name(:dep_delay),
            arrival_time = Name(:arr_time),
            scheduled_arrival_time = Name(:sched_arr_time),
            arrival_delay = Name(:arr_delay),
            tail_number = Name(:tailnum),
            destination = Name(:dest)
        )
(year = 2013, month = 1, day = 1, carrier = "UA", flight = 1545, origin = "EWR", air_time = 227, distance = 1400, hour = 5, minute = 15, time_hour = "2013-01-01 05:00:00", departure_time = 517, scheduled_departure_time = 515, departure_delay = 2, arrival_time = 830, scheduled_arrival_time = 819, arrival_delay = 11, tail_number = "N14228", destination = "IAH")
```

We can use our `airports` data to make datetimes with timezones.

```jldoctest dplyr
julia> scheduled_departure_time = ZonedDateTime(
            DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),
            airports[flight.origin].time_zone
        )
2013-01-01T05:15:00-05:00
```

Note the scheduled arrival time is `818`. This means `8:18`. We can use `divrem(_, 100)` to split it up. Note I'm accessing the `time_zone` with [`Name`](@ref) (which will default to `missing`). This is because some of the destinations are not in the `flights` dataset.

```jldoctest dplyr
julia> scheduled_arrival_time = ZonedDateTime(
            DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),
            Name(:time_zone)(airports[flight.destination])
        )
2013-01-01T08:19:00-06:00
```
What if it was an overnight flight? We can add a day to the arrival time if it wasn't later than the departure time.

```jldoctest dplyr
julia> if scheduled_arrival_time !== missing && !(scheduled_arrival_time > scheduled_departure_time)
            scheduled_arrival_time = scheduled_arrival_time + Day(1)
        end
```

Let's put it all together.

```jldoctest dplyr
julia> @noinline function process_flight(row)
            flight =
                @> row |>
                rename(_,
                    departure_time = Name(:dep_time),
                    scheduled_departure_time = Name(:sched_dep_time),
                    departure_delay = Name(:dep_delay),
                    arrival_time = Name(:arr_time),
                    scheduled_arrival_time = Name(:sched_arr_time),
                    arrival_delay = Name(:arr_delay),
                    tail_number = Name(:tailnum),
                    destination = Name(:dest)
                )
            scheduled_departure_time = ZonedDateTime(
                DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),
                airports[flight.origin].time_zone
            )
            scheduled_arrival_time = ZonedDateTime(
                DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),
                Name(:time_zone)(airports[flight.destination])
            )
            if scheduled_arrival_time !== missing && !(scheduled_arrival_time > scheduled_departure_time)
                scheduled_arrival_time = scheduled_arrival_time + Day(1)
            end
            @> flight |>
                transform(_,
                    scheduled_departure_time = scheduled_departure_time,
                    scheduled_arrival_time = scheduled_arrival_time,
                    air_time = Minute(_.air_time),
                    distance = _.distance * mi,
                    departure_delay = Minute(_.departure_delay),
                    arrival_delay = Minute(_.arrival_delay)
                ) |>
                remove(_, :year, :month, :day, :hour, :minute, :time_hour,
                    :departure_time, :arrival_time)
        end;

julia> flights =
        @> flights_file |>
        over(_, named_tuple) |>
        over(_, process_flight) |>
        make_columns |>
        rows;

julia> Peek(flights)
Showing 4 of 336776 rows
| :carrier | :flight | :origin |   :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |
| --------:| -------:| -------:| -----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|
|       UA |    1545 |     EWR | 227 minutes |   1400 mi | 2013-01-01T05:15:00-05:00 |        2 minutes | 2013-01-01T08:19:00-06:00 |     11 minutes |       N14228 |          IAH |
|       UA |    1714 |     LGA | 227 minutes |   1416 mi | 2013-01-01T05:29:00-05:00 |        4 minutes | 2013-01-01T08:30:00-06:00 |     20 minutes |       N24211 |          IAH |
|       AA |    1141 |     JFK | 160 minutes |   1089 mi | 2013-01-01T05:40:00-05:00 |        2 minutes | 2013-01-01T08:50:00-05:00 |     33 minutes |       N619AA |          MIA |
|       B6 |     725 |     JFK | 183 minutes |   1576 mi | 2013-01-01T05:45:00-05:00 |        -1 minute |                   missing |    -18 minutes |       N804JB |          BQN |
```

Theoretically, the distances between two airports is always the same. Let's make sure this is also the case in our data. First, [`order`](@ref) by `origin`, `destination`, and `distance`. Then [`Group`](@ref) [`By`](@ref) the same variables.

```jldoctest dplyr
julia> paths_grouped =
        @> flights |>
        order(_, Names(:origin, :destination, :distance)) |>
        Group(By(_, Names(:origin, :destination, :distance)));
```

Each `Group` will contain a [`key`](@ref) and [`value`](@ref)

```jldoctest dplyr
julia> path = first(paths_grouped);

julia> key(path)
(origin = "EWR", destination = "ALB", distance = 143 mi)

julia> value(path) |> Peek
Showing 4 of 439 rows
| :carrier | :flight | :origin |  :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |
| --------:| -------:| -------:| ----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|
|       EV |    4112 |     EWR | 33 minutes |    143 mi | 2013-01-01T13:17:00-05:00 |       -2 minutes | 2013-01-01T14:23:00-05:00 |    -10 minutes |       N13538 |          ALB |
|       EV |    3260 |     EWR | 36 minutes |    143 mi | 2013-01-01T16:21:00-05:00 |       34 minutes | 2013-01-01T17:24:00-05:00 |     40 minutes |       N19554 |          ALB |
|       EV |    4170 |     EWR | 31 minutes |    143 mi | 2013-01-01T20:04:00-05:00 |       52 minutes | 2013-01-01T21:12:00-05:00 |     44 minutes |       N12540 |          ALB |
|       EV |    4316 |     EWR | 33 minutes |    143 mi | 2013-01-02T13:27:00-05:00 |        5 minutes | 2013-01-02T14:33:00-05:00 |    -14 minutes |       N14153 |          ALB |
```

At this point, we don't need any of the `value` data. All we need is the `key`.

```jldoctest dplyr
julia> paths =
        @> paths_grouped |>
        over(_, key) |>
        make_columns |>
        rows;

julia> Peek(paths)
Showing 4 of 226 rows
| :origin | :destination | :distance |
| -------:| ------------:| ---------:|
|     EWR |          ALB |    143 mi |
|     EWR |          ANC |   3370 mi |
|     EWR |          ATL |    746 mi |
|     EWR |          AUS |   1504 mi |
```

Notice the data is already sorted by `origin` and `destination`, so that for our
second `Group`, we don't need to `order` first.

```jldoctest dplyr
julia> distinct_distances =
        @> paths |>
        Group(By(_, Names(:origin, :destination))) |>
        over(_, @_ transform(key(_),
            number = length(value(_))
        ));

julia> Peek(distinct_distances)
Showing at most 4 rows
| :origin | :destination | :number |
| -------:| ------------:| -------:|
|     EWR |          ALB |       1 |
|     EWR |          ANC |       1 |
|     EWR |          ATL |       1 |
|     EWR |          AUS |       1 |
```

Let's see [`when`](@ref) there are multiple distances for the same path:

```jldoctest dplyr
julia> @> distinct_distances |>
        when(_, @_ _.number != 1) |>
        Peek
Showing at most 4 rows
| :origin | :destination | :number |
| -------:| ------------:| -------:|
|     EWR |          EGE |       2 |
|     JFK |          EGE |       2 |
```

That's strange. What's up with the `EGE` airport? Let's take a [`Peek`](@ref).

```jldoctest dplyr
julia> @> flights |>
        when(_, @_ _.destination == "EGE") |>
        Peek
Showing at most 4 rows
| :carrier | :flight | :origin |   :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |
| --------:| -------:| -------:| -----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|
|       UA |    1597 |     EWR | 287 minutes |   1726 mi | 2013-01-01T09:28:00-05:00 |       -2 minutes | 2013-01-01T12:20:00-07:00 |     13 minutes |       N27733 |          EGE |
|       AA |     575 |     JFK | 280 minutes |   1747 mi | 2013-01-01T17:00:00-05:00 |       -5 minutes | 2013-01-01T19:50:00-07:00 |      3 minutes |       N5DRAA |          EGE |
|       UA |    1597 |     EWR | 261 minutes |   1726 mi | 2013-01-02T09:28:00-05:00 |         1 minute | 2013-01-02T12:20:00-07:00 |      3 minutes |       N24702 |          EGE |
|       AA |     575 |     JFK | 260 minutes |   1747 mi | 2013-01-02T17:00:00-05:00 |        5 minutes | 2013-01-02T19:50:00-07:00 |     16 minutes |       N631AA |          EGE |
```

Looks (to me) like two different sources are reporting different info about the
same flight.

# Interface

## Macros

```@docs
@_
@>
```

## Columns

```@docs
named_tuple
Name
Names
rename
transform
remove
gather
spread
```

## Rows

```@docs
unzip
Enumerated
over
indexed
when
order
By
Group
key
value
Join
Length
```

## Pivot

```@docs
item_names
rows
Peek
columns
make_columns
```
