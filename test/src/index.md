```@contents
```

# Tutorial

I'm using the data from the [dplyr tutorial](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html). The data is in the test folder of this package.

I created it with the following R code:

```R
library(nycflights13)
setwd("C:/Users/hp/.julia/dev/LightQuery/test")
write.csv(airports, "airports.csv", na = "", row.names = FALSE)
write.csv(flights, "flights.csv", na = "", row.names = FALSE)
write.csv(weathers, "weather.csv", na = "", row.names = FALSE)
```

Import tools from `Dates`, `TimeZones`, and `Unitful`.

```jldoctest dplyr
julia> using LightQuery

julia> using Dates: Date, DateTime, Hour

julia> using TimeZones: Class, Local, TimeZone, VariableTimeZone, ZonedDateTime

julia> using Unitful: °, °F, ft, hr, inch, mbar, mi, minute
```

## Airports cleaning

Use [`CSV.File`](http://juliadata.github.io/CSV.jl/stable/#CSV.File) to import the airports data.

```jldoctest dplyr
julia> import CSV

julia> airports_file = CSV.File("airports.csv", missingstrings = ["", "\\N"])
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

Convert the `schema` to [`row_info`](@ref).

```jldoctest dplyr
julia> using Tables: schema

julia> const Airport = row_info(schema(airports_file));
```

Read the first row.

```jldoctest dplyr
julia> airport = Airport(first(airports_file))
((`faa`, "04G"), (`name`, "Lansdowne Airport"), (`lat`, 41.1304722), (`lon`, -80.6195833), (`alt`, 1044), (`tz`, -5), (`dst`, "A"), (`tzone`, "America/New_York"))
```

[`rename`](@ref).

```jldoctest dplyr
julia> airport = @name rename(airport,
            airport_code = :faa,
            altitude = :alt,
            daylight_savings = :dst,
            latitude = :lat,
            longitude = :lon,
            time_zone = :tzone,
            time_zone_offset = :tz
        )
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`altitude`, 1044), (`daylight_savings`, "A"), (`latitude`, 41.1304722), (`longitude`, -80.6195833), (`time_zone`, "America/New_York"), (`time_zone_offset`, -5))
```

[`remove`](@ref) redundant data.

```jldoctest dplyr
julia> airport = @name remove(airport,
            :daylight_savings,
            :time_zone_offset
        )
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`altitude`, 1044), (`latitude`, 41.1304722), (`longitude`, -80.6195833), (`time_zone`, "America/New_York"))
```

Add units with [`transform`](@ref).

```jldoctest dplyr
julia> airport = @name transform(airport,
            altitude = airport.altitude * ft,
            latitude = airport.latitude * °,
            longitude = airport.longitude * °
        )
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`time_zone`, "America/New_York"), (`altitude`, 1044 ft), (`latitude`, 41.1304722°), (`longitude`, -80.6195833°))
```

Get a true `TimeZone`. Use [`@if_known`](@ref) to handle `missing` data. Note the data contains some `LEGACY` timezones. Use a type annotation: `TimeZone` is unstable without it.

```jldoctest dplyr
julia> get_time_zone(time_zone) = TimeZone(
            (@if_known time_zone),
            Class(:STANDARD) | Class(:LEGACY)
        )::VariableTimeZone;

julia> @name get_time_zone(airport.time_zone)
America/New_York (UTC-5/UTC-4)
```

Use the chaining macro [`@>`](@ref) to chain calls together.

```jldoctest dplyr
julia> function get_airport(row)
            @name @> Airport(row) |>
            rename(_,
                airport_code = :faa,
                altitude = :alt,
                daylight_savings = :dst,
                latitude = :lat,
                longitude = :lon,
                time_zone = :tzone,
                time_zone_offset = :tz
            ) |>
            remove(_,
                :daylight_savings,
                :time_zone_offset,
            ) |>
            transform(_,
                altitude = _.altitude * ft,
                latitude = _.latitude * °,
                longitude = _.longitude * °,
                time_zone = get_time_zone(_.time_zone)
            )
        end;

julia> get_airport(first(airports_file))
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`altitude`, 1044 ft), (`latitude`, 41.1304722°), (`longitude`, -80.6195833°), (`time_zone`, tz"America/New_York"))
```

[`over`](@ref) each row.

```jldoctest dplyr
julia> airports = over(airports_file, get_airport);

julia> first(airports)
((`name`, "Lansdowne Airport"), (`airport_code`, "04G"), (`altitude`, 1044 ft), (`latitude`, 41.1304722°), (`longitude`, -80.6195833°), (`time_zone`, tz"America/New_York"))
```

Call [`make_columns`](@ref) then [`to_rows`](@ref) to store the data column-wise but view it row-wise. [`Peek`](@ref) to view.

```jldoctest dplyr
julia> airports = to_rows(make_columns(airports));

julia> Peek(airports)
Showing 4 of 1458 rows
|                        `name` | `airport_code` | `altitude` |  `latitude` |  `longitude` |                    `time_zone` |
| -----------------------------:| --------------:| ----------:| -----------:| ------------:| ------------------------------:|
|             Lansdowne Airport |            04G |    1044 ft | 41.1304722° | -80.6195833° | America/New_York (UTC-5/UTC-4) |
| Moton Field Municipal Airport |            06A |     264 ft | 32.4605722° | -85.6800278° |  America/Chicago (UTC-6/UTC-5) |
|           Schaumburg Regional |            06C |     801 ft | 41.9893408° | -88.1012428° |  America/Chicago (UTC-6/UTC-5) |
|               Randall Airport |            06N |     523 ft |  41.431912° | -74.3915611° | America/New_York (UTC-5/UTC-4) |
```

[`index`](@ref) airports by code.

```jldoctest dplyr
julia> const indexed_airports = @name index(airports, :airport_code);

julia> indexed_airports["JFK"]
((`name`, "John F Kennedy Intl"), (`airport_code`, "JFK"), (`altitude`, 13 ft), (`latitude`, 40.639751°), (`longitude`, -73.778925°), (`time_zone`, tz"America/New_York"))
```

## Flights cleaning

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
```

Get the first flight, [`rename`](@ref), [`remove`](@ref), and [`transform`](@ref) to add units.

```jldoctest dplyr
julia> const Flight = row_info(schema(flights_file));

julia> flight =
        @name @> flights_file |>
        first |>
        Flight |>
        rename(_,
            arrival_delay = :arr_delay,
            arrival_time = :arr_time,
            departure_delay = :dep_delay,
            departure_time = :dep_time,
            destination = :dest,
            scheduled_arrival_time = :sched_arr_time,
            scheduled_departure_time = :sched_dep_time,
            tail_number = :tailnum
        ) |>
        remove(_,
            :arrival_time,
            :departure_time,
            :hour,
            :minute,
            :time_hour
        ) |>
        transform(_,
            air_time = _.air_time * minute,
            arrival_delay = _.arrival_delay * minute,
            departure_delay = _.departure_delay * minute,
            distance = _.distance * mi
        )
((`year`, 2013), (`month`, 1), (`day`, 1), (`carrier`, "UA"), (`flight`, 1545), (`origin`, "EWR"), (`destination`, "IAH"), (`scheduled_arrival_time`, 819), (`scheduled_departure_time`, 515), (`tail_number`, "N14228"), (`air_time`, 227 minute), (`arrival_delay`, 11 minute), (`departure_delay`, 2 minute), (`distance`, 1400 mi))
```

Find the `time_zone` of the `airport` the `flight` departed from. Use [`@if_known`](@ref) to handle `missing` data.

```jldoctest dplyr
julia> airport = @if_known @name get(indexed_airports, flight.origin, missing)
((`name`, "Newark Liberty Intl"), (`airport_code`, "EWR"), (`altitude`, 18 ft), (`latitude`, 40.6925°), (`longitude`, -74.168667°), (`time_zone`, tz"America/New_York"))

julia> time_zone = @if_known @name airport.time_zone
America/New_York (UTC-5/UTC-4)
```

Use `divrem(_, 100)` to split the `scheduled_departure_time`.

```jldoctest dplyr
julia> @name divrem(flight.scheduled_departure_time, 100)
(5, 15)
```

Create a `ZonedDateTime`.

```jldoctest dplyr
julia> @name ZonedDateTime(
            flight.year,
            flight.month,
            flight.day,
            divrem(flight.scheduled_departure_time, 100)...,
            time_zone
        )
2013-01-01T05:15:00-05:00
```

All together:

```jldoctest dplyr
julia> get_time(indexed_airports, flight, airport, time) =
            @name ZonedDateTime(
                flight.year,
                flight.month,
                flight.day,
                divrem(time, 100)...,
                @if_known (
                    @if_known get(indexed_airports, airport, missing)
                ).time_zone
            );

julia> @name get_time(
            indexed_airports,
            flight,
            flight.origin,
            flight.scheduled_departure_time
        )
2013-01-01T05:15:00-05:00
```

We can do the same for the `scheduled_arrival_time`.

```jldoctest dplyr
julia> arrival = @name get_time(
            indexed_airports,
            flight,
            flight.destination,
            flight.scheduled_arrival_time
        )
2013-01-01T08:19:00-06:00
```

All together.

```jldoctest dplyr
julia> function get_flight(indexed_airports, row)
            @name @> row |>
            Flight |>
            rename(_,
                arrival_delay = :arr_delay,
                arrival_time = :arr_time,
                departure_delay = :dep_delay,
                departure_time = :dep_time,
                destination = :dest,
                scheduled_arrival_time = :sched_arr_time,
                scheduled_departure_time = :sched_dep_time,
                tail_number = :tailnum
            ) |>
            remove(_,
                :arrival_time,
                :departure_time,
                :hour,
                :minute,
                :time_hour
            ) |>
            transform(_,
                air_time = _.air_time * minute,
                distance = _.distance * mi,
                departure_delay = _.departure_delay * minute,
                arrival_delay = _.arrival_delay * minute,
                scheduled_departure_time =
                    get_time(indexed_airports, _, _.origin, _.scheduled_departure_time),
                scheduled_arrival_time =
                    get_time(indexed_airports, _, _.destination, _.scheduled_arrival_time)
            ) |>
            remove(_,
                :year,
                :month,
                :day
            )
        end;

julia> get_flight(indexed_airports, first(flights_file))
((`carrier`, "UA"), (`flight`, 1545), (`origin`, "EWR"), (`destination`, "IAH"), (`tail_number`, "N14228"), (`air_time`, 227 minute), (`distance`, 1400 mi), (`departure_delay`, 2 minute), (`arrival_delay`, 11 minute), (`scheduled_departure_time`, ZonedDateTime(2013, 1, 1, 5, 15, tz"America/New_York")), (`scheduled_arrival_time`, ZonedDateTime(2013, 1, 1, 8, 19, tz"America/Chicago")))
```

[`over`](@ref) each row. Use [`@_`](@ref) to create an anonymous function.

```jldoctest dplyr
julia> flights =
        @> flights_file |>
        over(_, @_ get_flight(indexed_airports, _));

julia> flights =
        flights |>
        make_columns |>
        to_rows;

julia> Peek(flights)
Showing 4 of 336776 rows
| `carrier` | `flight` | `origin` | `destination` | `tail_number` | `air_time` | `distance` | `departure_delay` | `arrival_delay` | `scheduled_departure_time` |  `scheduled_arrival_time` |
| ---------:| --------:| --------:| -------------:| -------------:| ----------:| ----------:| -----------------:| ---------------:| --------------------------:| -------------------------:|
|        UA |     1545 |      EWR |           IAH |        N14228 | 227 minute |    1400 mi |          2 minute |       11 minute |  2013-01-01T05:15:00-05:00 | 2013-01-01T08:19:00-06:00 |
|        UA |     1714 |      LGA |           IAH |        N24211 | 227 minute |    1416 mi |          4 minute |       20 minute |  2013-01-01T05:29:00-05:00 | 2013-01-01T08:30:00-06:00 |
|        AA |     1141 |      JFK |           MIA |        N619AA | 160 minute |    1089 mi |          2 minute |       33 minute |  2013-01-01T05:40:00-05:00 | 2013-01-01T08:50:00-05:00 |
|        B6 |      725 |      JFK |           BQN |        N804JB | 183 minute |    1576 mi |         -1 minute |      -18 minute |  2013-01-01T05:45:00-05:00 |                   missing |
```

## Flights validation

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
| `carrier` | `flight` | `origin` | `destination` | `tail_number` | `air_time` | `distance` | `departure_delay` | `arrival_delay` | `scheduled_departure_time` |  `scheduled_arrival_time` |
| ---------:| --------:| --------:| -------------:| -------------:| ----------:| ----------:| -----------------:| ---------------:| --------------------------:| -------------------------:|
|        EV |     4112 |      EWR |           ALB |        N13538 |  33 minute |     143 mi |         -2 minute |      -10 minute |  2013-01-01T13:17:00-05:00 | 2013-01-01T14:23:00-05:00 |
|        EV |     3260 |      EWR |           ALB |        N19554 |  36 minute |     143 mi |         34 minute |       40 minute |  2013-01-01T16:21:00-05:00 | 2013-01-01T17:24:00-05:00 |
|        EV |     4170 |      EWR |           ALB |        N12540 |  31 minute |     143 mi |         52 minute |       44 minute |  2013-01-01T20:04:00-05:00 | 2013-01-01T21:12:00-05:00 |
|        EV |     4316 |      EWR |           ALB |        N14153 |  33 minute |     143 mi |          5 minute |      -14 minute |  2013-01-02T13:27:00-05:00 | 2013-01-02T14:33:00-05:00 |
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

Find the number of distinct distances.

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

[`Peek`](@ref) at flights going to `"EGE"` using [`when`](@ref).

```jldoctest dplyr
julia> @name @> flights |>
        when(_, @_ _.destination == "EGE") |>
        Peek
Showing at most 4 rows
| `carrier` | `flight` | `origin` | `destination` | `tail_number` | `air_time` | `distance` | `departure_delay` | `arrival_delay` | `scheduled_departure_time` |  `scheduled_arrival_time` |
| ---------:| --------:| --------:| -------------:| -------------:| ----------:| ----------:| -----------------:| ---------------:| --------------------------:| -------------------------:|
|        UA |     1597 |      EWR |           EGE |        N27733 | 287 minute |    1726 mi |         -2 minute |       13 minute |  2013-01-01T09:28:00-05:00 | 2013-01-01T12:20:00-07:00 |
|        AA |      575 |      JFK |           EGE |        N5DRAA | 280 minute |    1747 mi |         -5 minute |        3 minute |  2013-01-01T17:00:00-05:00 | 2013-01-01T19:50:00-07:00 |
|        UA |     1597 |      EWR |           EGE |        N24702 | 261 minute |    1726 mi |          1 minute |        3 minute |  2013-01-02T09:28:00-05:00 | 2013-01-02T12:20:00-07:00 |
|        AA |      575 |      JFK |           EGE |        N631AA | 260 minute |    1747 mi |          5 minute |       16 minute |  2013-01-02T17:00:00-05:00 | 2013-01-02T19:50:00-07:00 |
```

## Weather cleaning

Import weather data. Get the first row, [`rename`](@ref), [`remove`](@ref), and [`transform`](@ref) to add units.

```jldoctest dplyr
julia> weathers_file = CSV.File("weather.csv")
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

julia> const Weather = row_info(schema(weathers_file));

julia> function get_weather(indexed_airports, row)
            @name @> row |>
            Weather |>
            rename(_,
                airport_code = :origin,
                dew_point = :dewp,
                humidity = :humid,
                precipitation = :precip,
                temperature = :temp,
                visibility = :visib,
                wind_direction = :wind_dir
            ) |>
            transform(_,
                dew_point = _.dew_point * °F,
                humidity = _.humidity / 100,
                precipitation = _.precipitation * inch,
                pressure = _.pressure * mbar,
                temperature = _.temperature * °F,
                visibility = _.visibility * mi,
                wind_direction = _.wind_direction * °,
                wind_gust = _.wind_gust * mi / hr,
                wind_speed = _.wind_speed * mi / hr,
                date_time = ZonedDateTime(
                    _.year,
                    _.month,
                    _.day,
                    _.hour,
                    indexed_airports[_.airport_code].time_zone,
                    1
                )
            ) |>
            remove(_,
                :year,
                :month,
                :day,
                :hour
            )
        end;

julia> weathers =
        @> weathers_file |>
        over(_, @_ get_weather(indexed_airports, _));

julia> Peek(weathers)
Showing 4 of 26115 rows
|         `time_hour` | `airport_code` | `dew_point` |         `humidity` | `precipitation` |  `pressure` | `temperature` | `visibility` | `wind_direction` | `wind_gust` |      `wind_speed` |               `date_time` |
| -------------------:| --------------:| -----------:| ------------------:| ---------------:| -----------:| -------------:| ------------:| ----------------:| -----------:| -----------------:| -------------------------:|
| 2013-01-01 01:00:00 |            EWR |    26.06 °F |             0.5937 |        0.0 inch | 1012.0 mbar |      39.02 °F |      10.0 mi |             270° |     missing | 10.35702 mi hr^-1 | 2013-01-01T01:00:00-05:00 |
| 2013-01-01 02:00:00 |            EWR |    26.96 °F | 0.6163000000000001 |        0.0 inch | 1012.3 mbar |      39.02 °F |      10.0 mi |             250° |     missing |  8.05546 mi hr^-1 | 2013-01-01T02:00:00-05:00 |
| 2013-01-01 03:00:00 |            EWR |    28.04 °F | 0.6443000000000001 |        0.0 inch | 1012.5 mbar |      39.02 °F |      10.0 mi |             240° |     missing |  11.5078 mi hr^-1 | 2013-01-01T03:00:00-05:00 |
| 2013-01-01 04:00:00 |            EWR |    28.04 °F |             0.6221 |        0.0 inch | 1012.2 mbar |      39.92 °F |      10.0 mi |             250° |     missing | 12.65858 mi hr^-1 | 2013-01-01T04:00:00-05:00 |
```

## Joining flights and weather

I know that the weather data is already sorted by `airport_code` and `hour`.

To [`mix`](@ref) it with flights, [`order`](@ref) and [`Group`](@ref) `flights` [`By`](@ref) matching variables. Only use data [`when`](@ref) the `departure_delay` is present.

```jldoctest dplyr
julia> grouped_flights =
        @name @> flights |>
        when(_, @_ _.departure_delay !== missing) |>
        order(_, (:origin, :scheduled_departure_time)) |>
        Group(By(_, @_ (_.origin, floor(_.scheduled_departure_time, Hour))));

julia> key(first(grouped_flights))
("EWR", ZonedDateTime(2013, 1, 1, 5, tz"America/New_York"))
```

Now [`mix`](@ref).

```jldoctest dplyr
julia> weathers_to_flights = @name @> mix(:inner,
            By(weathers, @_ (_.airport_code, _.date_time)),
            By(grouped_flights, key)
        );
```

Look at the first match.

```jldoctest dplyr
julia> a_match = first(weathers_to_flights);

julia> weather, (flights_key, flights_value) = a_match;

julia> weather
((`time_hour`, "2013-01-01 05:00:00"), (`airport_code`, "EWR"), (`dew_point`, 28.04 °F), (`humidity`, 0.6443000000000001), (`precipitation`, 0.0 inch), (`pressure`, 1011.9 mbar), (`temperature`, 39.02 °F), (`visibility`, 10.0 mi), (`wind_direction`, 260°), (`wind_gust`, missing), (`wind_speed`, 12.65858 mi hr^-1), (`date_time`, ZonedDateTime(2013, 1, 1, 5, tz"America/New_York")))

julia> flights_key
("EWR", ZonedDateTime(2013, 1, 1, 5, tz"America/New_York"))

julia> Peek(flights_value)
| `carrier` | `flight` | `origin` | `destination` | `tail_number` | `air_time` | `distance` | `departure_delay` | `arrival_delay` | `scheduled_departure_time` |  `scheduled_arrival_time` |
| ---------:| --------:| --------:| -------------:| -------------:| ----------:| ----------:| -----------------:| ---------------:| --------------------------:| -------------------------:|
|        UA |     1545 |      EWR |           IAH |        N14228 | 227 minute |    1400 mi |          2 minute |       11 minute |  2013-01-01T05:15:00-05:00 | 2013-01-01T08:19:00-06:00 |
|        UA |     1696 |      EWR |           ORD |        N39463 | 150 minute |     719 mi |         -4 minute |       12 minute |  2013-01-01T05:58:00-05:00 | 2013-01-01T07:28:00-06:00 |
```

We're interested in `visibility` and `departure_delay`.

```jldoctest dplyr
julia> visibility = @name weather.visibility
10.0 mi

julia> @name over(flights_value, @_ (
            visibility = visibility,
            departure_delay = _.departure_delay
        )) |>
        Peek
| `visibility` | `departure_delay` |
| ------------:| -----------------:|
|      10.0 mi |          2 minute |
|      10.0 mi |         -4 minute |
```

All together.

```jldoctest dplyr
julia> function interested_in(a_match)
            weather, (flights_key, flights_value) = a_match
            visibility = @name weather.visibility
            @name over(flights_value, @_ (
                visibility = visibility,
                departure_delay = _.departure_delay
            ))
        end;

julia> Peek(interested_in(a_match))
| `visibility` | `departure_delay` |
| ------------:| -----------------:|
|      10.0 mi |          2 minute |
|      10.0 mi |         -4 minute |
```

Use `flatten` to unnest data (exported from Base).

```jldoctest dplyr
julia> data =
        @name @> weathers_to_flights |>
        over(_, interested_in) |>
        flatten |>
        make_columns |>
        to_rows;

julia> Peek(data)
Showing 4 of 326993 rows
| `visibility` | `departure_delay` |
| ------------:| -----------------:|
|      10.0 mi |          2 minute |
|      10.0 mi |         -4 minute |
|      10.0 mi |         -5 minute |
|      10.0 mi |         -2 minute |
```

## Visibility vs. departure delay

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
Showing 4 of 87 rows
| `visibility` | `departure_delay` |
| ------------:| -----------------:|
|       0.0 mi |         -5 minute |
|       0.0 mi |         -1 minute |
|       0.0 mi |         -8 minute |
|       0.0 mi |         -7 minute |
```

Calculate the mean `departure_delay`. Use [`to_columns`](@ref) to lazily view columns.

```jldoctest dplyr
julia> using Statistics: mean

julia> @name @> visibility_group |>
        value |>
        to_columns |>
        _.departure_delay |>
        mean
32.252873563218394 minute
```

For each group.

```jldoctest dplyr
julia> get_mean_departure_delay(visibility_group) = @name (
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
            over(_, get_mean_departure_delay) |>
            Peek(_, 20)
Showing at most 20 rows
| `visibility` |    `mean_departure_delay` | `count` |
| ------------:| -------------------------:| -------:|
|       0.0 mi | 32.252873563218394 minute |      87 |
|      0.06 mi |               22.2 minute |      85 |
|      0.12 mi |  50.69975186104218 minute |     403 |
|      0.25 mi | 20.481110254433307 minute |    1297 |
|       0.5 mi |   32.5890826383624 minute |    1319 |
|      0.75 mi |  30.06759906759907 minute |     429 |
|       1.0 mi |  32.24348473566642 minute |    1343 |
|      1.25 mi | 53.187845303867405 minute |     181 |
|       1.5 mi |  25.90661478599222 minute |    1542 |
|      1.75 mi | 43.333333333333336 minute |     132 |
|       2.0 mi | 22.701923076923077 minute |    2912 |
|       2.5 mi |  21.18074398249453 minute |    2285 |
|       3.0 mi |   21.2113218731476 minute |    3374 |
|       4.0 mi |  19.48311444652908 minute |    2132 |
|       5.0 mi |  21.10387902695595 minute |    4563 |
|       6.0 mi | 19.807032301480483 minute |    5944 |
|       7.0 mi | 19.208963745361118 minute |    7006 |
|       8.0 mi |  19.98660103910309 minute |    7314 |
|       9.0 mi | 18.762949476558944 minute |   10985 |
|      10.0 mi | 10.951549367828692 minute |  273660 |
```

This data suggests that low visibility levels lead to larger departure delays,
on average.

## Reshaping

For this section, I will use [data from the Global Historical Climatology Network](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/ACW00011604.dly). I got this idea from the [`tidyr` tutorial](https://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html).

```jldoctest dplyr
julia> file = open("climate.txt");

julia> line = readline(file)
"ACW00011604194901TMAX  289  X  289  X  283  X  283  X  289  X  289  X  278  X  267  X  272  X  278  X  267  X  278  X  267  X  267  X  278  X  267  X  267  X  272  X  272  X  272  X  278  X  272  X  267  X  267  X  267  X  278  X  272  X  272  X  272  X  272  X  272  X"

julia> close(file)
```

Parse the first chunk.

```jldoctest dplyr
julia> month_variable = @name (
            year = parse(Int, SubString(line, 12, 15)),
            month = parse(Int, SubString(line, 16, 17)),
            variable = Symbol(SubString(line, 18, 21))
        )
((`year`, 1949), (`month`, 1), (`variable`, :TMAX))
```

Parse a day. `missing` is represented by `-9999`.

```jldoctest dplyr
julia> function get_day(line, day)
            start = 14 + 8 * day
            value = parse(Int, line[start:start + 4])
            @name (day = day, value =
                if value == -9999
                    missing
                else
                    value
                end
            )
        end;

julia> get_day(line, 1)
((`day`, 1), (`value`, 289))
```

[`over`](@ref) each day.

```jldoctest dplyr
julia> days = @> over(1:31, @_ (
            month_variable...,
            get_day(line, _)...
        ));

julia> first(days)
((`year`, 1949), (`month`, 1), (`variable`, :TMAX), (`day`, 1), (`value`, 289))
```

Use [`when`](@ref) to remove missing data;

```jldoctest dplyr
julia> days = @name when(days, @_ _.value !== missing);

julia> first(days)
((`year`, 1949), (`month`, 1), (`variable`, :TMAX), (`day`, 1), (`value`, 289))
```

Use [`transform`](@ref) and [`remove`](@ref) to create a `Date`.

```jldoctest dplyr
julia> get_date(day) =
        @name @> day |>
        transform(_, date = Date(_.year, _.month, _.day)) |>
        remove(_, :year, :month, :day);

julia> get_date(first(days))
((`variable`, :TMAX), (`value`, 289), (`date`, 1949-01-01))
```

All together.

```jldoctest dplyr
julia> function get_month_variable(line)
            month_variable = @name (
                year = parse(Int, SubString(line, 12, 15)),
                month = parse(Int, SubString(line, 16, 17)),
                variable = Symbol(SubString(line, 18, 21))
            )
            @name @> over(1:31, @_ (
                month_variable...,
                get_day(line, _)...
            )) |>
            when(_, @_ _.value !== missing) |>
            over(_, get_date)
        end;

julia> first(get_month_variable(line))
((`variable`, :TMAX), (`value`, 289), (`date`, 1949-01-01))
```

[`over`](@ref) each line. Use `flatten` to unnest data.

```jldoctest dplyr
julia> climate_data =
        @> eachline("climate.txt") |>
        over(_, get_month_variable) |>
        flatten |>
        make_columns |>
        to_rows;

julia> Peek(climate_data)
Showing 4 of 1231 rows
| `variable` | `value` |     `date` |
| ----------:| -------:| ----------:|
|      :TMAX |     289 | 1949-01-01 |
|      :TMAX |     289 | 1949-01-02 |
|      :TMAX |     283 | 1949-01-03 |
|      :TMAX |     283 | 1949-01-04 |
```

Sort and group by `date`.

```jldoctest dplyr
julia> by_date =
        @name @> climate_data |>
        order(_, :date) |>
        Group(By(_, :date));

julia> day_variables = first(by_date);

julia> key(day_variables)
1949-01-01

julia> value(day_variables) |> Peek
Showing 4 of 5 rows
| `variable` | `value` |     `date` |
| ----------:| -------:| ----------:|
|      :TMAX |     289 | 1949-01-01 |
|      :TMIN |     217 | 1949-01-01 |
|      :PRCP |       0 | 1949-01-01 |
|      :SNOW |       0 | 1949-01-01 |
```

[`over`](@ref) each variable. Use [`Name`](@ref) to make a `Name`. This is unavoidably type-unstable.

```jldoctest dplyr
julia> spread_variables(day_variables) = @name (
            date = key(day_variables),
            over(
                value(day_variables),
                @_ (Name(_.variable), _.value)
            )...
        );

julia> spread_variables(day_variables)
((`date`, 1949-01-01), (`TMAX`, 289), (`TMIN`, 217), (`PRCP`, 0), (`SNOW`, 0), (`SNWD`, 0))
```

[`over`](@ref) each day.

```jldoctest dplyr
julia> @> by_date |>
        over(_, spread_variables) |>
        Peek
Showing at most 4 rows
|  `WT16` |     `date` | `TMAX` | `TMIN` | `PRCP` | `SNOW` | `SNWD` |
| -------:| ----------:| ------:| ------:| ------:| ------:| ------:|
| missing | 1949-01-01 |    289 |    217 |      0 |      0 |      0 |
|       1 | 1949-01-02 |    289 |    228 |     30 |      0 |      0 |
| missing | 1949-01-03 |    283 |    222 |      0 |      0 |      0 |
|       1 | 1949-01-04 |    283 |    233 |      0 |      0 |      0 |
```

# Interface

## Macros

```@docs
@_
@>
@if_known
@name
```

## Values

```@docs
if_else
key
value
Name
unname
backwards
```

## Columns

```@docs
named_tuple
rename
transform
remove
gather
spread
Apply
row_info
```

## Rows

```@docs
Enumerate
over
index
when
order
By
Group
mix
distinct
```

## Tables

```@docs
to_rows
Peek
to_columns
make_columns
```
