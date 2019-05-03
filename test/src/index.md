# Tutorial

I'm using the data from the [dplyr tutorial](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html). The data is in the test folder of this package. I created it with the following R code:

```R
library(nycflights13)
setwd("C:/Users/hp/.julia/dev/LightQuery/test")
write.csv(airports, "airports.csv", na = "", row.names = FALSE)
write.csv(flights, "flights.csv", na = "", row.names = FALSE)
```

Import tools from `Dates`, `TimeZones`, and `Unitful`.

```jldoctest dplyr
julia> using LightQuery

julia> using Dates: DateTime, Day

julia> import Dates: Minute

julia> Minute(::Missing) = missing;

julia> using TimeZones: Class, TimeZone, VariableTimeZone, ZonedDateTime

julia> using Unitful: °, ft, mi
```

Use [`CSV.File`](http://juliadata.github.io/CSV.jl/stable/#CSV.File) to import the airports data.

```jldoctest dplyr
julia> import CSV

julia> const airports_file = CSV.File("airports.csv",
            allowmissing = :auto,
            missingstrings = ["", "\\N"]
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
 :tzone  Union{Missing, String}
```

Use [`named_schema`](@ref) to get an object to convert a table row to a named tuple.

```jldoctest dplyr
julia> const Airport = named_schema(airports_file)
((`faa`, Val{String}()), (`name`, Val{String}()), (`lat`, Val{Float64}()), (`lon`, Val{Float64}()), (`alt`, Val{Int64}()), (`tz`, Val{Int64}()), (`dst`, Val{String}()), (`tzone`, Val{Union{Missing, String}}()))
```

For this package, I've created my own version of `NamedTuples`. Use [`@name`](@ref) to work with them.

Read the first row. Use the chaining macro [`@>`](@ref) to chain calls together.

```jldoctest dplyr
julia> airport =
        @> airports_file |>
        first |>
        Airport
((`faa`, "04G"), (`name`, "Lansdowne Airport"), (`lat`, 41.1304722), (`lon`, -80.6195833), (`alt`, 1044), (`tz`, -5), (`dst`, "A"), (`tzone`, "America/New_York"))
```

[`rename`](@ref).

```jldoctest dplyr
julia> airport =
        @name @> airport |>
        rename(_,
            airport_code = :faa,
            latitude = :lat,
            longitude = :lon,
            altitude = :alt,
            time_zone_offset = :tz,
            daylight_savings = :dst,
            time_zone = :tzone
        )
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`latitude`, 41.1304722), (`longitude`, -80.6195833), (`altitude`, 1044), (`time_zone_offset`, -5), (`daylight_savings`, "A"), (`time_zone`, "America/New_York"))
```

[`transform`](@ref) `time_zone` into a `TimeZone`. Note the data contains some `LEGACY` timezones. Use a type annotation: `TimeZone` is unstable without it.

```jldoctest dplyr
julia> const time_zone_classes = Class(:STANDARD) | Class(:LEGACY);

julia> airport =
        @name @> airport |>
        transform(_,
            time_zone = TimeZone(_.time_zone, time_zone_classes)::VariableTimeZone
        )
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`latitude`, 41.1304722), (`longitude`, -80.6195833), (`altitude`, 1044), (`time_zone_offset`, -5), (`daylight_savings`, "A"), (`time_zone`, tz"America/New_York"))
```

[`remove`](@ref) data contingent on timezone.

```jldoctest dplyr
julia> airport =
        @name @> airport |>
        remove(_,
            :time_zone_offset,
            :daylight_savings
        )
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`latitude`, 41.1304722), (`longitude`, -80.6195833), (`altitude`, 1044), (`time_zone`, tz"America/New_York"))
```

Add units.

```jldoctest dplyr
julia> airport =
        @name @> airport |>
        transform(_,
            latitude = _.latitude * °,
            longitude = _.longitude * °,
            altitude = _.altitude * ft
        )
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`time_zone`, tz"America/New_York"), (`latitude`, 41.1304722°), (`longitude`, -80.6195833°), (`altitude`, 1044 ft))
```

All together:

```jldoctest dplyr
julia> function process_airport(row)
            @name @> row |>
            Airport |>
            rename(_,
                airport_code = :faa,
                latitude = :lat,
                longitude = :lon,
                altitude = :alt,
                time_zone_offset = :tz,
                daylight_savings = :dst,
                time_zone = :tzone
            ) |>
            transform(_,
                time_zone =
                    if _.time_zone === missing
                        missing
                    else
                        TimeZone(_.time_zone, time_zone_classes)::VariableTimeZone
                    end,
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

Use [`over`](@ref) to lazily `map`.

```jldoctest dplyr
julia> airports =
        @> airports_file |>
        over(_, process_airport);
```

Call [`make_columns`](@ref) then [`to_rows`](@ref) to store the data column-wise but view it row-wise.

```jldoctest dplyr
julia> airports =
        airports |>
        make_columns |>
        to_rows;
```

[`Peek`](@ref).

```jldoctest dplyr
julia> Peek(airports)
Showing 4 of 1458 rows
|                        `name` | `airport_code` |                    `time_zone` |  `latitude` |  `longitude` | `altitude` |
| -----------------------------:| --------------:| ------------------------------:| -----------:| ------------:| ----------:|
|             Lansdowne Airport |            04G | America/New_York (UTC-5/UTC-4) | 41.1304722° | -80.6195833° |    1044 ft |
| Moton Field Municipal Airport |            06A |  America/Chicago (UTC-6/UTC-5) | 32.4605722° | -85.6800278° |     264 ft |
|           Schaumburg Regional |            06C |  America/Chicago (UTC-6/UTC-5) | 41.9893408° | -88.1012428° |     801 ft |
|               Randall Airport |            06N | America/New_York (UTC-5/UTC-4) |  41.431912° | -74.3915611° |     523 ft |
```

[`index`](@ref) airports by code.

```jldoctest dplyr
julia> const indexed_airports =
        @name @> airports |>
        index(_, :airport_code);

julia> indexed_airports["JFK"]
((`name`, "John F Kennedy Intl"), (`airport_code`, "JFK"), (`time_zone`, tz"America/New_York"), (`latitude`, 40.639751°), (`longitude`, -73.778925°), (`altitude`, 13 ft))
```

Use [`CSV.File`](http://juliadata.github.io/CSV.jl/stable/#CSV.File) to import the flights data.

```jldoctest dplyr
julia> const flights_file = CSV.File("flights.csv", allowmissing = :auto)
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

julia> const Flight = named_schema(flights_file);
```

Read and [`rename`](@ref) the first flight.

```jldoctest dplyr
julia> flight =
        @name @> flights_file |>
        first |>
        Flight |>
        rename(_,
            departure_time = :dep_time,
            scheduled_departure_time = :sched_dep_time,
            departure_delay = :dep_delay,
            arrival_time = :arr_time,
            scheduled_arrival_time = :sched_arr_time,
            arrival_delay = :arr_delay,
            tail_number = :tailnum,
            destination = :dest
        )
((`year`, 2013), (`month`, 1), (`day`, 1), (`carrier`, "UA"), (`flight`, 1545), (`origin`, "EWR"), (`air_time`, 227), (`distance`, 1400), (`hour`, 5), (`minute`, 15), (`time_hour`, "2013-01-01 05:00:00"), (`departure_time`, 517), (`scheduled_departure_time`, 515), (`departure_delay`, 2), (`arrival_time`, 830), (`scheduled_arrival_time`, 819), (`arrival_delay`, 11), (`tail_number`, "N14228"), (`destination`, "IAH"))
```
Use `airports` data to add timezones.

```jldoctest dplyr
julia> scheduled_departure_time = @name ZonedDateTime(
            DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),
            indexed_airports[flight.origin].time_zone
        )
2013-01-01T05:15:00-05:00
```

Not all destination airports are not in the `flights` data, and not all airports have time zone data. Use `divrem(_, 100)` to split the arrival time (`818` -> `8:18`). If it was an overnight flight, add a day to the arrival time.

```jldoctest dplyr
julia> destination_airport =
        @name get(indexed_airports, flight.destination, missing);

julia> scheduled_arrival_time =
            if destination_airport === missing
                missing
            else
                if @name destination_airport.time_zone === missing
                    missing
                else
                    maybe_arrival_time = @name ZonedDateTime(
                        DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),
                        destination_airport.time_zone
                    )
                    if maybe_arrival_time < scheduled_departure_time
                        maybe_arrival_time + Day(1)
                    else
                        maybe_arrival_time
                    end
                end
            end
2013-01-01T08:19:00-06:00
```

Add times and units and remove redundant varibbles.

```jldoctest dplyr
julia> flight =
        @name @> flight |>
        transform(_,
            scheduled_departure_time = scheduled_departure_time,
            scheduled_arrival_time = scheduled_arrival_time,
            air_time = Minute(_.air_time),
            distance = _.distance * mi,
            departure_delay = Minute(_.departure_delay),
            arrival_delay = Minute(_.arrival_delay)
        ) |>
        remove(_,
            :year,
            :month,
            :day,
            :hour,
            :minute,
            :time_hour,
            :departure_time,
            :arrival_time
        )
((`carrier`, "UA"), (`flight`, 1545), (`origin`, "EWR"), (`tail_number`, "N14228"), (`destination`, "IAH"), (`scheduled_departure_time`, ZonedDateTime(2013, 1, 1, 5, 15, tz"America/New_York")), (`scheduled_arrival_time`, ZonedDateTime(2013, 1, 1, 8, 19, tz"America/Chicago")), (`air_time`, 227 minutes), (`distance`, 1400 mi), (`departure_delay`, 2 minutes), (`arrival_delay`, 11 minutes))
```

All together:

```jldoctest dplyr
julia> function process_flight(row)
            flight =
                @name @> row |>
                Flight |>
                rename(_,
                    departure_time = :dep_time,
                    scheduled_departure_time = :sched_dep_time,
                    departure_delay = :dep_delay,
                    arrival_time = :arr_time,
                    scheduled_arrival_time = :sched_arr_time,
                    arrival_delay = :arr_delay,
                    tail_number = :tailnum,
                    destination = :dest
                )
            scheduled_departure_time =
                @name ZonedDateTime(
                    DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),
                    indexed_airports[flight.origin].time_zone
                )
            destination_airport = @name get(indexed_airports, flight.destination, missing)
            scheduled_arrival_time =
                if destination_airport === missing
                    missing
                else
                    if @name destination_airport.time_zone === missing
                        missing
                    else
                        maybe_arrival_time = @name ZonedDateTime(
                            DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),
                            destination_airport.time_zone
                        )
                        if maybe_arrival_time < scheduled_departure_time
                            maybe_arrival_time + Day(1)
                        else
                            maybe_arrival_time
                        end
                    end
                end
            @name @> flight |>
            transform(_,
                scheduled_departure_time = scheduled_departure_time,
                scheduled_arrival_time = scheduled_arrival_time,
                air_time = Minute(_.air_time),
                distance = _.distance * mi,
                departure_delay = Minute(_.departure_delay),
                arrival_delay = Minute(_.arrival_delay)
            ) |>
            remove(_,
                :year,
                :month,
                :day,
                :hour,
                :minute,
                :time_hour,
                :departure_time,
                :arrival_time
            )
        end;

julia> flights =
        @> flights_file |>
        over(_, process_flight) |>
        make_columns |>
        to_rows;

julia> Peek(flights)
Showing 4 of 336776 rows
| `carrier` | `flight` | `origin` | `tail_number` | `destination` | `scheduled_departure_time` |  `scheduled_arrival_time` |  `air_time` | `distance` | `departure_delay` | `arrival_delay` |
| ---------:| --------:| --------:| -------------:| -------------:| --------------------------:| -------------------------:| -----------:| ----------:| -----------------:| ---------------:|
|        UA |     1545 |      EWR |        N14228 |           IAH |  2013-01-01T05:15:00-05:00 | 2013-01-01T08:19:00-06:00 | 227 minutes |    1400 mi |         2 minutes |      11 minutes |
|        UA |     1714 |      LGA |        N24211 |           IAH |  2013-01-01T05:29:00-05:00 | 2013-01-01T08:30:00-06:00 | 227 minutes |    1416 mi |         4 minutes |      20 minutes |
|        AA |     1141 |      JFK |        N619AA |           MIA |  2013-01-01T05:40:00-05:00 | 2013-01-01T08:50:00-05:00 | 160 minutes |    1089 mi |         2 minutes |      33 minutes |
|        B6 |      725 |      JFK |        N804JB |           BQN |  2013-01-01T05:45:00-05:00 |                   missing | 183 minutes |    1576 mi |         -1 minute |     -18 minutes |
```

Theoretically, the distances between two airports is always the same. Make sure this is the case in our data. First, [`order`](@ref) by `origin`, `destination`, and `distance`. Then [`Group`](@ref) [`By`](@ref) the same variables.

```jldoctest dplyr
julia> paths_grouped =
        @name @> flights |>
        order(_, (:origin, :destination, :distance)) |>
        Group(By(_, (:origin, :destination, :distance)));
```

Each [`Group`](@ref) contains a [`key`](@ref) and [`value`](@ref)

```jldoctest dplyr
julia> path = first(paths_grouped);

julia> key(path)
((`origin`, "EWR"), (`destination`, "ALB"), (`distance`, 143 mi))

julia> value(path) |> Peek
Showing 4 of 439 rows
| `carrier` | `flight` | `origin` | `tail_number` | `destination` | `scheduled_departure_time` |  `scheduled_arrival_time` | `air_time` | `distance` | `departure_delay` | `arrival_delay` |
| ---------:| --------:| --------:| -------------:| -------------:| --------------------------:| -------------------------:| ----------:| ----------:| -----------------:| ---------------:|
|        EV |     4112 |      EWR |        N13538 |           ALB |  2013-01-01T13:17:00-05:00 | 2013-01-01T14:23:00-05:00 | 33 minutes |     143 mi |        -2 minutes |     -10 minutes |
|        EV |     3260 |      EWR |        N19554 |           ALB |  2013-01-01T16:21:00-05:00 | 2013-01-01T17:24:00-05:00 | 36 minutes |     143 mi |        34 minutes |      40 minutes |
|        EV |     4170 |      EWR |        N12540 |           ALB |  2013-01-01T20:04:00-05:00 | 2013-01-01T21:12:00-05:00 | 31 minutes |     143 mi |        52 minutes |      44 minutes |
|        EV |     4316 |      EWR |        N14153 |           ALB |  2013-01-02T13:27:00-05:00 | 2013-01-02T14:33:00-05:00 | 33 minutes |     143 mi |         5 minutes |     -14 minutes |
```

All we need is the `key`.

```jldoctest dplyr
julia> paths =
        @> paths_grouped |>
        over(_, key) |>
        make_columns |>
        to_rows;

julia> Peek(paths)
Showing 4 of 226 rows
| `origin` | `destination` | `distance` |
| --------:| -------------:| ----------:|
|      EWR |           ALB |     143 mi |
|      EWR |           ANC |    3370 mi |
|      EWR |           ATL |     746 mi |
|      EWR |           AUS |    1504 mi |
```

The data is already sorted by `origin` and `destination`, so that for our second `Group`, we don't need to `order` first. Use [`@_`](@ref) to create an anonymous function.

```jldoctest dplyr
julia> distinct_distances =
        @name @> paths |>
        Group(By(_, (:origin, :destination))) |>
        over(_, @_ transform(key(_),
            number = length(value(_))
        ));

julia> Peek(distinct_distances)
Showing at most 4 rows
| `origin` | `destination` | `number` |
| --------:| -------------:| --------:|
|      EWR |           ALB |        1 |
|      EWR |           ANC |        1 |
|      EWR |           ATL |        1 |
|      EWR |           AUS |        1 |
```

See [`when`](@ref) there are multiple distances for the same path:

```jldoctest dplyr
julia> @name @> distinct_distances |>
        when(_, @_ _.number != 1) |>
        Peek
Showing at most 4 rows
| `origin` | `destination` | `number` |
| --------:| -------------:| --------:|
|      EWR |           EGE |        2 |
|      JFK |           EGE |        2 |
```

[`Peek`](@ref) at flights going to `"EGE"`.

```jldoctest dplyr
julia> @name @> flights |>
        when(_, @_ _.destination == "EGE") |>
        Peek
Showing at most 4 rows
| `carrier` | `flight` | `origin` | `tail_number` | `destination` | `scheduled_departure_time` |  `scheduled_arrival_time` |  `air_time` | `distance` | `departure_delay` | `arrival_delay` |
| ---------:| --------:| --------:| -------------:| -------------:| --------------------------:| -------------------------:| -----------:| ----------:| -----------------:| ---------------:|
|        UA |     1597 |      EWR |        N27733 |           EGE |  2013-01-01T09:28:00-05:00 | 2013-01-01T12:20:00-07:00 | 287 minutes |    1726 mi |        -2 minutes |      13 minutes |
|        AA |      575 |      JFK |        N5DRAA |           EGE |  2013-01-01T17:00:00-05:00 | 2013-01-01T19:50:00-07:00 | 280 minutes |    1747 mi |        -5 minutes |       3 minutes |
|        UA |     1597 |      EWR |        N24702 |           EGE |  2013-01-02T09:28:00-05:00 | 2013-01-02T12:20:00-07:00 | 261 minutes |    1726 mi |          1 minute |       3 minutes |
|        AA |      575 |      JFK |        N631AA |           EGE |  2013-01-02T17:00:00-05:00 | 2013-01-02T19:50:00-07:00 | 260 minutes |    1747 mi |         5 minutes |      16 minutes |
```

# Interface

## Macros

```@docs
@_
@>
@name
```

## Columns

```@docs
rename
transform
remove
gather
spread
named_schema
```

## Rows

```@docs
unzip
Enumerated
over
index
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
to_rows
Peek
to_columns
make_columns
```
