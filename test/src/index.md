# Tutorial

I'm using the data from the [dplyr tutorial](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html). The data is in the test folder of this package.

I created it with the following R code:
```R
library(nycflights13)
setwd("C:/Users/hp/.julia/dev/LightQuery/test")
write.csv(airports, "airports.csv", na = "", row.names = FALSE)
write.csv(flights, "flights.csv", na = "", row.names = FALSE)
```

Import tools from `Dates`, `TimeZones`, and `Unitful`.

```jldoctest dplyr
julia> using LightQuery

julia> using Dates: DateTime, Day, Hour

julia> using TimeZones: Class, TimeZone, VariableTimeZone, ZonedDateTime

julia> using Unitful: °, °F, ft, hr, inch, mbar, mi, minute
```

Use [`CSV.File`](http://juliadata.github.io/CSV.jl/stable/#CSV.File) to import the airports data.

```jldoctest dplyr
julia> import CSV

julia> airports_file = CSV.File("airports.csv",
            missingstrings = ["", "\\N"]
        )
CSV.File("airports.csv"):
Size: 1458 x 8
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

For this package, I made [`named_tuple`](@ref)s to replace `NamedTuple`s. Use [`@name`](@ref) to work with them.

Convert the `schema` to a [`named_tuple`](@ref).

```jldoctest dplyr
julia> using Tables: schema

julia> const Airport = named_tuple(schema(airports_file))
((`faa`, Val{String}()), (`name`, Val{String}()), (`lat`, Val{Float64}()), (`lon`, Val{Float64}()), (`alt`, Val{Int64}()), (`tz`, Val{Int64}()), (`dst`, Val{String}()), (`tzone`, Val{Union{Missing, String}}()))
```

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
julia> flights_file = CSV.File("flights.csv")
CSV.File("flights.csv"):
Size: 336776 x 19
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

julia> const Flight = named_tuple(schema(flights_file));
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
            air_time = _.air_time * minute,
            distance = _.distance * mi,
            departure_delay = _.departure_delay * minute,
            arrival_delay = _.arrival_delay * minute
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
((`carrier`, "UA"), (`flight`, 1545), (`origin`, "EWR"), (`tail_number`, "N14228"), (`destination`, "IAH"), (`scheduled_departure_time`, ZonedDateTime(2013, 1, 1, 5, 15, tz"America/New_York")), (`scheduled_arrival_time`, ZonedDateTime(2013, 1, 1, 8, 19, tz"America/Chicago")), (`air_time`, 227 minute), (`distance`, 1400 mi), (`departure_delay`, 2 minute), (`arrival_delay`, 11 minute))
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
                air_time = _.air_time * minute,
                distance = _.distance * mi,
                departure_delay = _.departure_delay * minute,
                arrival_delay = _.arrival_delay * minute
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
| `carrier` | `flight` | `origin` | `tail_number` | `destination` | `scheduled_departure_time` |  `scheduled_arrival_time` | `air_time` | `distance` | `departure_delay` | `arrival_delay` |
| ---------:| --------:| --------:| -------------:| -------------:| --------------------------:| -------------------------:| ----------:| ----------:| -----------------:| ---------------:|
|        UA |     1545 |      EWR |        N14228 |           IAH |  2013-01-01T05:15:00-05:00 | 2013-01-01T08:19:00-06:00 | 227 minute |    1400 mi |          2 minute |       11 minute |
|        UA |     1714 |      LGA |        N24211 |           IAH |  2013-01-01T05:29:00-05:00 | 2013-01-01T08:30:00-06:00 | 227 minute |    1416 mi |          4 minute |       20 minute |
|        AA |     1141 |      JFK |        N619AA |           MIA |  2013-01-01T05:40:00-05:00 | 2013-01-01T08:50:00-05:00 | 160 minute |    1089 mi |          2 minute |       33 minute |
|        B6 |      725 |      JFK |        N804JB |           BQN |  2013-01-01T05:45:00-05:00 |                   missing | 183 minute |    1576 mi |         -1 minute |      -18 minute |
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
|        EV |     4112 |      EWR |        N13538 |           ALB |  2013-01-01T13:17:00-05:00 | 2013-01-01T14:23:00-05:00 |  33 minute |     143 mi |         -2 minute |      -10 minute |
|        EV |     3260 |      EWR |        N19554 |           ALB |  2013-01-01T16:21:00-05:00 | 2013-01-01T17:24:00-05:00 |  36 minute |     143 mi |         34 minute |       40 minute |
|        EV |     4170 |      EWR |        N12540 |           ALB |  2013-01-01T20:04:00-05:00 | 2013-01-01T21:12:00-05:00 |  31 minute |     143 mi |         52 minute |       44 minute |
|        EV |     4316 |      EWR |        N14153 |           ALB |  2013-01-02T13:27:00-05:00 | 2013-01-02T14:33:00-05:00 |  33 minute |     143 mi |          5 minute |      -14 minute |
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

The data is already sorted by `origin` and `destination`, so for our second `Group`, we don't need to `order` first. Use [`@_`](@ref) to create an anonymous function.

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
| `carrier` | `flight` | `origin` | `tail_number` | `destination` | `scheduled_departure_time` |  `scheduled_arrival_time` | `air_time` | `distance` | `departure_delay` | `arrival_delay` |
| ---------:| --------:| --------:| -------------:| -------------:| --------------------------:| -------------------------:| ----------:| ----------:| -----------------:| ---------------:|
|        UA |     1597 |      EWR |        N27733 |           EGE |  2013-01-01T09:28:00-05:00 | 2013-01-01T12:20:00-07:00 | 287 minute |    1726 mi |         -2 minute |       13 minute |
|        AA |      575 |      JFK |        N5DRAA |           EGE |  2013-01-01T17:00:00-05:00 | 2013-01-01T19:50:00-07:00 | 280 minute |    1747 mi |         -5 minute |        3 minute |
|        UA |     1597 |      EWR |        N24702 |           EGE |  2013-01-02T09:28:00-05:00 | 2013-01-02T12:20:00-07:00 | 261 minute |    1726 mi |          1 minute |        3 minute |
|        AA |      575 |      JFK |        N631AA |           EGE |  2013-01-02T17:00:00-05:00 | 2013-01-02T19:50:00-07:00 | 260 minute |    1747 mi |          5 minute |       16 minute |
```

Import weather data.

```jldoctest dplyr
julia> const weathers_file = CSV.File("weather.csv")
CSV.File("weather.csv"):
Size: 26115 x 15
Tables.Schema:
 :origin      String
 :year        Int64
 :month       Int64
 :day         Int64
 :hour        Int64
 :temp        Union{Missing, Float64}
 :dewp        Union{Missing, Float64}
 :humid       Union{Missing, Float64}
 :wind_dir    Union{Missing, Int64}
 :wind_speed  Union{Missing, Float64}
 :wind_gust   Union{Missing, Float64}
 :precip      Float64
 :pressure    Union{Missing, Float64}
 :visib       Float64
 :time_hour   String

julia> const Weather = named_tuple(schema(weathers_file));

julia> function process_weather(row)
            @name @> row |>
            Weather |>
            rename(_,
                airport_code = :origin,
                temperature = :temp,
                dew_point = :dewp,
                humidity = :humid,
                wind_direction = :wind_dir,
                precipitation = :precip,
                visibility = :visib
            ) |>
            transform(_,
                hour = ZonedDateTime(
                    DateTime(_.year, _.month, _.day, _.hour),
                    indexed_airports[_.airport_code].time_zone,
                    1
                ),
                wind_speed = _.wind_speed * mi / hr,
                wind_gust = _.wind_gust * mi / hr,
                pressure = _.pressure * mbar,
                temperature = _.temperature * °F,
                dew_point = _.dew_point * °F,
                humidity = _.humidity / 100,
                wind_direction = _.wind_direction * °,
                precipitation = _.precipitation * inch,
                visibility = _.visibility * mi
            ) |>
            remove(_,
                :year,
                :month,
                :day
            )
        end;

julia> weathers =
        @> weathers_file |>
        over(_, process_weather);
```

I know that the weather data is already sorted by `airport_code` and `hour`.

To [`Join`](@ref) it with flights, [`order`](@ref) and [`Group`](@ref) `flights`
[`By`](@ref) matching variables.

```jldoctest dplyr
julia> grouped_flights =
        @name @> flights |>
        when(_, @_ _.departure_delay !== missing) |>
        order(_, (:origin, :scheduled_departure_time)) |>
        Group(By(_, @_ (_.origin, round(_.scheduled_departure_time, Hour))));

julia> weathers_flights = @name @> Join(
            By(weathers, @_ (_.airport_code, _.hour)),
            By(grouped_flights, key)
        );
```

Look at the first match.

```ldoctest dplyr
julia> first(weathers_flights)
(((`time_hour`, "2013-01-01 01:00:00"), (`airport_code`, "EWR"), (`visibility`, 10.0), (`hour`, ZonedDateTime(2013, 1, 1, 1, tz"America/New_York")), (`wind_speed`, 10.35702 mi hr^-1), (`wind_gust`, missing), (`pressure`, 1012.0 mbar), (`temperature`, 39.02 °F), (`dew_point`, 26.06 °F), (`humidity`, 0.5937), (`wind_direction`, 270°), (`precipitation`, 0.0 inch)), missing)
```

There is no flights in the first hour at `EWR`, so the second item in the pair is `missing`. To only consider full matches, use [`when`](@ref).

```jldoctest dplyr
julia> weathers_flights =
        @> weathers_flights |>
        when(_, @_ _[1] !== missing && _[2] !== missing);
```

Look at the first match.

```jldoctest dplyr
julia> (weather, (flights_key, flights_value)) = first(weathers_flights);

julia> weather
((`time_hour`, "2013-01-01 05:00:00"), (`airport_code`, "EWR"), (`hour`, ZonedDateTime(2013, 1, 1, 5, tz"America/New_York")), (`wind_speed`, 12.65858 mi hr^-1), (`wind_gust`, missing), (`pressure`, 1011.9 mbar), (`temperature`, 39.02 °F), (`dew_point`, 28.04 °F), (`humidity`, 0.6443000000000001), (`wind_direction`, 260°), (`precipitation`, 0.0 inch), (`visibility`, 10.0 mi))

julia> flights_key
("EWR", ZonedDateTime(2013, 1, 1, 5, tz"America/New_York"))

julia> Peek(flights_value)
| `carrier` | `flight` | `origin` | `tail_number` | `destination` | `scheduled_departure_time` |  `scheduled_arrival_time` | `air_time` | `distance` | `departure_delay` | `arrival_delay` |
| ---------:| --------:| --------:| -------------:| -------------:| --------------------------:| -------------------------:| ----------:| ----------:| -----------------:| ---------------:|
|        UA |     1545 |      EWR |        N14228 |           IAH |  2013-01-01T05:15:00-05:00 | 2013-01-01T08:19:00-06:00 | 227 minute |    1400 mi |          2 minute |       11 minute |
```

Use [`over`](@ref) to merge the weather data into the matching flights.

```jldoctest dplyr
julia> @> flights_value |>
        over(_, @_ merge(_, weather)) |>
        Peek
| `carrier` | `flight` | `origin` | `tail_number` | `destination` | `scheduled_departure_time` |  `scheduled_arrival_time` | `air_time` | `distance` | `departure_delay` | `arrival_delay` |         `time_hour` | `airport_code` |                    `hour` |      `wind_speed` | `wind_gust` |  `pressure` | `temperature` | `dew_point` |         `humidity` | `wind_direction` | `precipitation` | `visibility` |
| ---------:| --------:| --------:| -------------:| -------------:| --------------------------:| -------------------------:| ----------:| ----------:| -----------------:| ---------------:| -------------------:| --------------:| -------------------------:| -----------------:| -----------:| -----------:| -------------:| -----------:| ------------------:| ----------------:| ---------------:| ------------:|
|        UA |     1545 |      EWR |        N14228 |           IAH |  2013-01-01T05:15:00-05:00 | 2013-01-01T08:19:00-06:00 | 227 minute |    1400 mi |          2 minute |       11 minute | 2013-01-01 05:00:00 |            EWR | 2013-01-01T05:00:00-05:00 | 12.65858 mi hr^-1 |     missing | 1011.9 mbar |      39.02 °F |    28.04 °F | 0.6443000000000001 |             260° |        0.0 inch |      10.0 mi |
```

All together:

```jldoctest dplyr
julia> function process_weather_flights(row)
            (weather, (flights_key, flights_value)) = row
            @> flights_value |>
            over(_, @_ merge(_, weather))
        end;
```

Use `flatten` to unnest data.

```jldoctest dplyr
julia> data =
        @name @> weathers_flights |>
        over(_, process_weather_flights) |>
        flatten |>
        make_columns |>
        to_rows;
```

How does visibility affect `departure_delay`? Group by visibility.

```jldoctest dplyr
julia> by_visibility =
        @name @> data |>
        order(_, :visibility) |>
        Group(By(_, :visibility));

julia> visibility_group = first(by_visibility);

julia> key(visibility_group)
0.0 mi

julia> value(visibility_group) |> Peek
Showing 4 of 88 rows
| `carrier` | `flight` | `origin` | `tail_number` | `destination` | `scheduled_departure_time` |  `scheduled_arrival_time` | `air_time` | `distance` | `departure_delay` | `arrival_delay` |         `time_hour` | `airport_code` |                    `hour` |     `wind_speed` | `wind_gust` |  `pressure` | `temperature` | `dew_point` | `humidity` | `wind_direction` | `precipitation` | `visibility` |
| ---------:| --------:| --------:| -------------:| -------------:| --------------------------:| -------------------------:| ----------:| ----------:| -----------------:| ---------------:| -------------------:| --------------:| -------------------------:| ----------------:| -----------:| -----------:| -------------:| -----------:| ----------:| ----------------:| ---------------:| ------------:|
|        AA |     1141 |      JFK |        N5EHAA |           MIA |  2013-01-30T05:40:00-05:00 | 2013-01-30T08:50:00-05:00 | 149 minute |    1089 mi |         -5 minute |      -17 minute | 2013-01-30 06:00:00 |            JFK | 2013-01-30T06:00:00-05:00 | 9.20624 mi hr^-1 |     missing | 1013.4 mbar |      44.06 °F |    44.06 °F |        1.0 |             160° |        0.0 inch |       0.0 mi |
|        B6 |      725 |      JFK |        N636JB |           BQN |  2013-01-30T05:40:00-05:00 |                   missing | 183 minute |    1576 mi |         -1 minute |      -11 minute | 2013-01-30 06:00:00 |            JFK | 2013-01-30T06:00:00-05:00 | 9.20624 mi hr^-1 |     missing | 1013.4 mbar |      44.06 °F |    44.06 °F |        1.0 |             160° |        0.0 inch |       0.0 mi |
|        B6 |      135 |      JFK |        N516JB |           RSW |  2013-01-30T06:00:00-05:00 | 2013-01-30T09:12:00-05:00 | 169 minute |    1074 mi |         -8 minute |        5 minute | 2013-01-30 06:00:00 |            JFK | 2013-01-30T06:00:00-05:00 | 9.20624 mi hr^-1 |     missing | 1013.4 mbar |      44.06 °F |    44.06 °F |        1.0 |             160° |        0.0 inch |       0.0 mi |
|        B6 |      125 |      JFK |        N649JB |           FLL |  2013-01-30T06:00:00-05:00 | 2013-01-30T09:06:00-05:00 | 150 minute |    1069 mi |         -7 minute |       -6 minute | 2013-01-30 06:00:00 |            JFK | 2013-01-30T06:00:00-05:00 | 9.20624 mi hr^-1 |     missing | 1013.4 mbar |      44.06 °F |    44.06 °F |        1.0 |             160° |        0.0 inch |       0.0 mi |
```

Calculate the mean `departure_delay`. Use [`to_columns`](@ref) to lazily view
columns.

```jldoctest dplyr
julia> using Statistics: mean

julia> @name @> visibility_group |>
        value |>
        to_columns |>
        _.departure_delay |>
        mean
29.022727272727273 minute
```

For each group.

```jldoctest dplyr
julia> process_visibility_group(visibility_group) = @name (
            visibility = key(visibility_group),
            mean_departure_delay =
                (@> visibility_group |>
                value |>
                to_columns |>
                _.departure_delay |>
                mean),
            count = length(value(visibility_group))
        );

julia> @> by_visibility |>
            over(_, process_visibility_group) |>
            Peek(_, maximum_length = 20) |> show
Showing at most 20 rows
| `visibility` |    `mean_departure_delay` | `count` |
| ------------:| -------------------------:| -------:|
|       0.0 mi | 29.022727272727273 minute |      88 |
|      0.06 mi | 19.370786516853933 minute |      89 |
|      0.12 mi | 47.931372549019606 minute |     408 |
|      0.25 mi | 21.117740652346857 minute |    1257 |
|       0.5 mi |  31.68247895944912 minute |    1307 |
|      0.75 mi |  33.76546391752577 minute |     388 |
|       1.0 mi | 30.030150753768844 minute |    1393 |
|      1.25 mi |  60.91812865497076 minute |     171 |
|       1.5 mi | 24.203585147247118 minute |    1562 |
|      1.75 mi |  46.20161290322581 minute |     124 |
|       2.0 mi | 20.668558077436582 minute |    2996 |
|       2.5 mi |  20.01099868015838 minute |    2273 |
|       3.0 mi | 21.653651266766023 minute |    3355 |
|       4.0 mi |  18.78944820909971 minute |    2066 |
|       5.0 mi | 21.710416207883725 minute |    4541 |
|       6.0 mi | 19.966545328479807 minute |    5769 |
|       7.0 mi | 18.860371383330936 minute |    6947 |
|       8.0 mi | 19.698917268184342 minute |    7204 |
|       9.0 mi |  18.30856204978572 minute |   10967 |
|      10.0 mi | 11.034410273815128 minute |  274017 |
```

This data suggests that low visibility levels lead to larger departure delays,
on average.

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
named_tuple
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
