# Beginner tutorial

```@contents
```

I'm using the data from the [dplyr tutorial](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html). The data is in the test folder of this package.

I created it with the following R code:

```R
library(nycflights13)
setwd("C:/Users/hp/.julia/dev/LightQuery/test")
write.csv(airports, "airports.csv", na = "", row.names = FALSE)
write.csv(flights, "flights.csv", na = "", row.names = FALSE)
write.csv(weathers, "weather.csv", na = "", row.names = FALSE)
```

First, import some tools we will need and change the working directory.

```jldoctest flights
julia> using LightQuery

julia> using Dates: Date, DateTime, Hour

julia> using Base.Iterators: flatten

julia> using TimeZones: Class, Local, TimeZone, VariableTimeZone, ZonedDateTime

julia> using Unitful: °, °F, ft, hr, inch, mbar, mi, minute

julia> cd(joinpath(pkgdir(LightQuery), "test"));

```

## Airports cleaning

The first step in cleaning up this data is to create a dataset about airports. The airports data crucially contains timezone information which we will need to adjust flight times.

Use [`CSV.File`](http://juliadata.github.io/CSV.jl/stable/#CSV.File) to import the airports data. Immediately use [`Rows`](@ref) to iterate over the rows of the file.

```jldoctest flights
julia> using CSV: File

julia> airports_file = Rows(File("airports.csv", missingstrings = ["", "\\N"]));
```

Let's read in the first row and try to process it.

```jldoctest flights
julia> airport = first(airports_file)
(dst = "A", tz = -5, tzone = "America/New_York", name = "Lansdowne Airport", lat = 41.1304722, alt = 1044, faa = "04G", lon = -80.6195833)
```

Next, [`rename`](@ref) the variables to be human readable.

```jldoctest flights
julia> airport = rename(airport,
            airport_code = name"faa",
            altitude = name"alt",
            daylight_savings = name"dst",
            latitude = name"lat",
            longitude = name"lon",
            time_zone = name"tzone",
            time_zone_offset = name"tz"
        )
(name = "Lansdowne Airport", airport_code = "04G", altitude = 1044, daylight_savings = "A", latitude = 41.1304722, longitude = -80.6195833, time_zone = "America/New_York", time_zone_offset = -5)
```

Next, [`remove`](@ref) redundant data. This data is associated with timezones, not flights.

```jldoctest flights
julia> airport = remove(airport,
            name"daylight_savings",
            name"time_zone_offset"
        )
(name = "Lansdowne Airport", airport_code = "04G", altitude = 1044, latitude = 41.1304722, longitude = -80.6195833, time_zone = "America/New_York")
```

Next, add units to some of our variables using [`transform`](@ref).

```jldoctest flights
julia> airport = transform(airport,
            altitude = airport.altitude * ft,
            latitude = airport.latitude * °,
            longitude = airport.longitude * °
        )
(name = "Lansdowne Airport", airport_code = "04G", time_zone = "America/New_York", altitude = 1044 ft, latitude = 41.1304722°, longitude = -80.6195833°)
```

Next, we will write a function for getting a true timezone. This will be useful because the departure and arrival times are in various timezones. Use [`@if_known`](@ref) to handle `missing` data. Note the data contains some `LEGACY` timezones. Note that the type annotation is optional: `TimeZone` is unstable without it.

```jldoctest flights
julia> get_time_zone(time_zone) = TimeZone(
            (@if_known time_zone),
            Class(:STANDARD) | Class(:LEGACY)
        )::VariableTimeZone;

julia> get_time_zone(airport.time_zone)
America/New_York (UTC-5/UTC-4)
```

Next, put all of our row processing steps together into one function. You can use the all-purpose chaining macro [`@>`](@ref) provided in this package to chain all of these steps together.

```jldoctest flights
julia> function get_airport(row)
            @> row |>
            rename(_,
                airport_code = name"faa",
                altitude = name"alt",
                daylight_savings = name"dst",
                latitude = name"lat",
                longitude = name"lon",
                time_zone = name"tzone",
                time_zone_offset = name"tz"
            ) |>
            remove(_,
                name"daylight_savings",
                name"time_zone_offset",
            ) |>
            transform(_,
                altitude = _.altitude * ft,
                latitude = _.latitude * °,
                longitude = _.longitude * °,
                time_zone = get_time_zone(_.time_zone)
            )
        end;

julia> get_airport(first(airports_file))
(name = "Lansdowne Airport", airport_code = "04G", altitude = 1044 ft, latitude = 41.1304722°, longitude = -80.6195833°, time_zone = tz"America/New_York")
```

Use [`over`](@ref) to lazily map this function over each row of the airports file. `over` is simply `Base.Generator` with the argument order reversed. This facilitates chaining.

```jldoctest flights
julia> airports = over(airports_file, get_airport);
```

I will repeat the following sequence of operations many times in this tutorial. Call [`make_columns`](@ref) to store the data as columns. Then, because it is useful to view the data as rows, use [`Rows`](@ref) to lazily view the data row-wise. You can use [`Peek`](@ref) to look at the first few rows of data.

```jldoctest flights
julia> airports = Rows(; make_columns(airports)...);
```

You can use [`index`](@ref) to be able to quickly retrieve airports by code. This will be helpful later. This is very similar to making a `Dict`.

```jldoctest flights
julia> const indexed_airports = index(airports, name"airport_code");
```

## Flights cleaning

Now that we have built our airports dataset, we can start working on the flights data. Start by using [`CSV.File`](http://juliadata.github.io/CSV.jl/stable/#CSV.File) to lazily import the flights data.

```jldoctest flights
julia> flights_file = Rows(File("flights.csv"));
```

Again, we will build a function to clean up a row of data. We will again use the first row to build and test our function. I will skip over several steps that we already used in the airports data: get the first flight, [`rename`](@ref), [`remove`](@ref), and [`transform`](@ref) to add units.

```jldoctest flights
julia> flight =
        @> flights_file |>
        first |>
        rename(_,
            arrival_delay = name"arr_delay",
            arrival_time = name"arr_time",
            departure_delay = name"dep_delay",
            departure_time = name"dep_time",
            destination = name"dest",
            scheduled_arrival_time = name"sched_arr_time",
            scheduled_departure_time = name"sched_dep_time",
            tail_number = name"tailnum"
        ) |>
        remove(_,
            name"arrival_time",
            name"departure_time",
            name"hour",
            name"minute",
            name"time_hour"
        ) |>
        transform(_,
            air_time = _.air_time * minute,
            arrival_delay = _.arrival_delay * minute,
            departure_delay = _.departure_delay * minute,
            distance = _.distance * mi
        )
(flight = 1545, origin = "EWR", year = 2013, carrier = "UA", day = 1, month = 1, destination = "IAH", scheduled_arrival_time = 819, scheduled_departure_time = 515, tail_number = "N14228", air_time = 227 minute, arrival_delay = 11 minute, departure_delay = 2 minute, distance = 1400 mi)
```

Let's find the `time_zone` of the `airport` the `flight` departed from. Use [`@if_known`](@ref) to handle `missing` data.

```jldoctest flights
julia> airport = @if_known get(indexed_airports, flight.origin, missing)
(name = "Newark Liberty Intl", airport_code = "EWR", altitude = 18 ft, latitude = 40.6925°, longitude = -74.168667°, time_zone = tz"America/New_York")

julia> time_zone = @if_known airport.time_zone
America/New_York (UTC-5/UTC-4)
```

Now process the departure time. We are given times as hours and minutes concatenated together. Use `divrem(_, 100)` to split the `scheduled_departure_time`.

```jldoctest flights
julia> divrem(flight.scheduled_departure_time, 100)
(5, 15)
```

Let's build a `ZonedDateTime` for the departure time.

```jldoctest flights
julia> ZonedDateTime(
            flight.year,
            flight.month,
            flight.day,
            divrem(flight.scheduled_departure_time, 100)...,
            time_zone
        )
2013-01-01T05:15:00-05:00
```

We can combine the steps for creating a ZonedDateTime into one function. Then we can use it for both the departure and the arrival times.

```jldoctest flights
julia> get_time(indexed_airports, flight, airport, time) =
            ZonedDateTime(
                flight.year,
                flight.month,
                flight.day,
                divrem(time, 100)...,
                @if_known (
                    @if_known get(indexed_airports, airport, missing)
                ).time_zone
            );

julia> get_time(
            indexed_airports,
            flight,
            flight.origin,
            flight.scheduled_departure_time
        )
2013-01-01T05:15:00-05:00
```

We also used this function to build the `scheduled_arrival_time`.

```jldoctest flights
julia> arrival = get_time(
            indexed_airports,
            flight,
            flight.destination,
            flight.scheduled_arrival_time
        )
2013-01-01T08:19:00-06:00
```

Let's combine all of the flights row processing steps into one function.

```jldoctest flights
julia> function get_flight(indexed_airports, row)
            @> row |>
            rename(_,
                arrival_delay = name"arr_delay",
                arrival_time = name"arr_time",
                departure_delay = name"dep_delay",
                departure_time = name"dep_time",
                destination = name"dest",
                scheduled_arrival_time = name"sched_arr_time",
                scheduled_departure_time = name"sched_dep_time",
                tail_number = name"tailnum"
            ) |>
            remove(_,
                name"arrival_time",
                name"departure_time",
                name"hour",
                name"minute",
                name"time_hour"
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
                name"year",
                name"month",
                name"day"
            )
        end;

julia> get_flight(indexed_airports, first(flights_file))
(flight = 1545, origin = "EWR", carrier = "UA", destination = "IAH", tail_number = "N14228", air_time = 227 minute, distance = 1400 mi, departure_delay = 2 minute, arrival_delay = 11 minute, scheduled_departure_time = ZonedDateTime(2013, 1, 1, 5, 15, tz"America/New_York"), scheduled_arrival_time = ZonedDateTime(2013, 1, 1, 8, 19, tz"America/Chicago"))
```

Again, use [`over`](@ref) to lazily map this function over each row. Here we are using the [`@_`](@ref) macro to create an anonymous function as tersely as possible. Finally, we will again use [`make_columns`](@ref) and [`Rows`](@ref) to store the data column-wise and view it row-wise. Again use [`Peek`](@ref) to view the first few rows.

```jldoctest flights
julia> flights =
        @> flights_file |>
        over(_, @_ get_flight(indexed_airports, _));
```

## Grouping and validating flights

Now that we have cleaned the data, what should we do with? One simple question we might want to answer is whether the distances between two airports is always the same. If this is not the case, there is an inconsistency in the data. Answering this question will also allow me to show off the grouping features of the package. For both joining and grouping, LightQuery requires your data to be pre-sorted. This is greatly improves performance. Consider keeping your data pre-sorted to begin with!

Thus, first, we will need to [`order`](@ref) flights by `origin`, `destination`, and `distance`. Note that we are using a tuple of [`Name`](@ref)s as a selector function to pass to `order`. Once the data is in order, we can  [`Group`](@ref) [`By`](@ref) the same variables. [`By`](@ref) is necessary before grouping and joining to tell LightQuery how your data is ordered. All flights with the same origin, destination, and distance will be put into one group.

```jldoctest flights
julia> paths_grouped =
        @> flights |>
        order(_, (name"origin", name"destination", name"distance")) |>
        Group(By(_, (name"origin", name"destination", name"distance")));

```

Each [`Group`](@ref) contains a [`key`](@ref) and [`value`](@ref). The [`key`](@ref) is what we use to group the rows, and the [`value`](@ref) is a group of rows which all have the same key. We can look at the first few rows in a group using [`Peek`](@ref).

```jldoctest flights
julia> path = first(paths_grouped);

julia> key(path)
(origin = "EWR", destination = "ALB", distance = 143 mi)

julia> value(path) |> Peek
Showing 4 of 439 rows
| flight | origin | carrier | destination | tail_number |  air_time | distance | departure_delay | arrival_delay |  scheduled_departure_time |    scheduled_arrival_time |
| ------:| ------:| -------:| -----------:| -----------:| ---------:| --------:| ---------------:| -------------:| -------------------------:| -------------------------:|
|   4112 |    EWR |      EV |         ALB |      N13538 | 33 minute |   143 mi |       -2 minute |    -10 minute | 2013-01-01T13:17:00-05:00 | 2013-01-01T14:23:00-05:00 |
|   3260 |    EWR |      EV |         ALB |      N19554 | 36 minute |   143 mi |       34 minute |     40 minute | 2013-01-01T16:21:00-05:00 | 2013-01-01T17:24:00-05:00 |
|   4170 |    EWR |      EV |         ALB |      N12540 | 31 minute |   143 mi |       52 minute |     44 minute | 2013-01-01T20:04:00-05:00 | 2013-01-01T21:12:00-05:00 |
|   4316 |    EWR |      EV |         ALB |      N14153 | 33 minute |   143 mi |        5 minute |    -14 minute | 2013-01-02T13:27:00-05:00 | 2013-01-02T14:33:00-05:00 |
```

For the purposes of our analysis, all we need is the `key`. As always, store the data as columns using [`make_columns`](@ref), lazily view it as rows using [`Rows`](@ref), and use [`Peek`](@ref) to view the first few rows.

```jldoctest flights
julia> paths =
        @> paths_grouped |>
        over(_, key) |>
        make_columns |>
        Rows(; _ ...);

julia> Peek(paths)
Showing 4 of 226 rows
| origin | destination | distance |
| ------:| -----------:| --------:|
|    EWR |         ALB |   143 mi |
|    EWR |         ANC |  3370 mi |
|    EWR |         ATL |   746 mi |
|    EWR |         AUS |  1504 mi |
```

Let's run our data through a second round of grouping. This time, we will group data only by origin and destination. Theoretically, each group should only be one row long, because the distance between an origin and destination airport should always be the same. Our data is already sorted, so we do not need to sort it again before grouping. Again, use [`Group`](@ref) and [`By`](@ref) to group the rows. Again, we can pass a tuple of [`Name`](@ref)s as a selector function. Then, for each group, we can find the number of rows it contains.

```jldoctest flights
julia> path_groups =
        @> paths |>
        Group(By(_, (name"origin", name"destination")));
```

Let's create a function to add the number of distinct distances to the `key`.

```jldoctest flights
julia> first_path_group = first(path_groups);

julia> key(first_path_group)
(origin = "EWR", destination = "ALB")

julia> Peek(value(first_path_group))
| origin | destination | distance |
| ------:| -----------:| --------:|
|    EWR |         ALB |   143 mi |

julia> function with_number((key, value))
            transform(key, number = length(value))
        end;

julia> with_number(first_path_group)
(origin = "EWR", destination = "ALB", number = 1)
```

We can take a [`Peek`](@ref) at the first few results.

```jldoctest flights
julia> distinct_distances =
        @> path_groups |>
        over(_, with_number);

julia> Peek(distinct_distances)
Showing at most 4 rows
| origin | destination | number |
| ------:| -----------:| ------:|
|    EWR |         ALB |      1 |
|    EWR |         ANC |      1 |
|    EWR |         ATL |      1 |
|    EWR |         AUS |      1 |
```

Let's see [`when`](@ref) there are multiple distances for the same path. `when` is simply `Iterators.filter` with the argument order reversed. This facilitates chaining. Again, use [`@_`](@ref) to create an anonymous function to pass to [`when`](@ref).

```jldoctest flights
julia> @> distinct_distances |>
        when(_, @_ _.number != 1) |>
        Peek
Showing at most 4 rows
| origin | destination | number |
| ------:| -----------:| ------:|
|    EWR |         EGE |      2 |
|    JFK |         EGE |      2 |
```

It looks like there is a consistency with flights which arrive at at the `EGE` airport. Let's take a [`Peek`](@ref) at flights going to `"EGE"` using [`when`](@ref). Again, use [`@_`](@ref) to create an anonymous function to pass to [`when`](@ref).

```jldoctest flights
julia> @> flights |>
        when(_, @_ _.destination == "EGE") |>
        Peek
Showing at most 4 rows
| flight | origin | carrier | destination | tail_number |   air_time | distance | departure_delay | arrival_delay |  scheduled_departure_time |    scheduled_arrival_time |
| ------:| ------:| -------:| -----------:| -----------:| ----------:| --------:| ---------------:| -------------:| -------------------------:| -------------------------:|
|   1597 |    EWR |      UA |         EGE |      N27733 | 287 minute |  1726 mi |       -2 minute |     13 minute | 2013-01-01T09:28:00-05:00 | 2013-01-01T12:20:00-07:00 |
|    575 |    JFK |      AA |         EGE |      N5DRAA | 280 minute |  1747 mi |       -5 minute |      3 minute | 2013-01-01T17:00:00-05:00 | 2013-01-01T19:50:00-07:00 |
|   1597 |    EWR |      UA |         EGE |      N24702 | 261 minute |  1726 mi |        1 minute |      3 minute | 2013-01-02T09:28:00-05:00 | 2013-01-02T12:20:00-07:00 |
|    575 |    JFK |      AA |         EGE |      N631AA | 260 minute |  1747 mi |        5 minute |     16 minute | 2013-01-02T17:00:00-05:00 | 2013-01-02T19:50:00-07:00 |
```

You can see just in these rows that there is an inconsistency in the data. The distance for the first two rows should be the same as the distance for the second two rows.

## Weather cleaning

Perhaps I want to know weather influences the departure delay. To do this, I will need to join weather data into the flights data. Start by cleaning the weather data using basically the same steps as above. Get the first row, [`rename`](@ref), [`remove`](@ref), and [`transform`](@ref) to add units.

TODO: collect weather then try again

```jldoctest flights
julia> weathers_file = Rows(File("weather.csv"));

julia> function get_weather(indexed_airports, row)
            @> row |>
            rename(_,
                airport_code = name"origin",
                dew_point = name"dewp",
                humidity = name"humid",
                precipitation = name"precip",
                temperature = name"temp",
                visibility = name"visib",
                wind_direction = name"wind_dir"
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
                name"year",
                name"month",
                name"day",
                name"hour"
            )
        end;

julia> weathers =
        @> weathers_file |>
        over(_, @_ get_weather(indexed_airports, _));

julia> Peek(weathers)
Showing 4 of 26115 rows
|           time_hour | airport_code | dew_point |           humidity | precipitation |    pressure | temperature | visibility | wind_direction | wind_gust |        wind_speed |                 date_time |
| -------------------:| ------------:| ---------:| ------------------:| -------------:| -----------:| -----------:| ----------:| --------------:| ---------:| -----------------:| -------------------------:|
| 2013-01-01 01:00:00 |          EWR |  26.06 °F |             0.5937 |      0.0 inch | 1012.0 mbar |    39.02 °F |    10.0 mi |           270° |   missing | 10.35702 mi hr^-1 | 2013-01-01T01:00:00-05:00 |
| 2013-01-01 02:00:00 |          EWR |  26.96 °F | 0.6163000000000001 |      0.0 inch | 1012.3 mbar |    39.02 °F |    10.0 mi |           250° |   missing |  8.05546 mi hr^-1 | 2013-01-01T02:00:00-05:00 |
| 2013-01-01 03:00:00 |          EWR |  28.04 °F | 0.6443000000000001 |      0.0 inch | 1012.5 mbar |    39.02 °F |    10.0 mi |           240° |   missing |  11.5078 mi hr^-1 | 2013-01-01T03:00:00-05:00 |
| 2013-01-01 04:00:00 |          EWR |  28.04 °F |             0.6221 |      0.0 inch | 1012.2 mbar |    39.92 °F |    10.0 mi |           250° |   missing | 12.65858 mi hr^-1 | 2013-01-01T04:00:00-05:00 |
```

## Joining flights and weather

I happen to know that the weather data is already sorted by `airport_code` and `hour`. However, we will need to presort and group the flights before we can join in the weather file. Joining in LightQuery is never many-to-one; you always need to explicitly group first. This is slightly less convenient but allows some extra flexibility.

[`order`](@ref) and [`Group`](@ref) `flights` [`By`](@ref) matching variables. We will join the flights to the weather data by rounding down the scheduled departure time of the flight to the nearest hour. Only use data [`when`](@ref) the `departure_delay` is present.

```jldoctest flights
julia> grouped_flights =
        @> flights |>
        when(_, @_ _.departure_delay !== missing) |>
        order(_, (name"origin", name"scheduled_departure_time")) |>
        Group(By(_, @_ (_.origin, floor(_.scheduled_departure_time, Hour))));

julia> key(first(grouped_flights))
("EWR", ZonedDateTime(2013, 1, 1, 5, tz"America/New_York"))
```

An inner join will find pairs rows with matching [`key`](@ref)s. Groups of flights are already sorted by [`key`](@ref).

```jldoctest flights
julia> weathers_to_flights = @> InnerJoin(
            By(weathers, @_ (_.airport_code, _.date_time)),
            By(grouped_flights, key)
        );

```

Let's look at the first match. This will contain weather data, and a group of flights.

```jldoctest flights
julia> a_match = first(weathers_to_flights);

julia> weather, (flights_key, flights_value) = a_match;

julia> weather
(time_hour = "2013-01-01 05:00:00", airport_code = "EWR", dew_point = 28.04 °F, humidity = 0.6443000000000001, precipitation = 0.0 inch, pressure = 1011.9 mbar, temperature = 39.02 °F, visibility = 10.0 mi, wind_direction = 260°, wind_gust = missing, wind_speed = 12.65858 mi hr^-1, date_time = ZonedDateTime(2013, 1, 1, 5, tz"America/New_York"))

julia> flights_key
("EWR", ZonedDateTime(2013, 1, 1, 5, tz"America/New_York"))

julia> Peek(flights_value)
| flight | origin | carrier | destination | tail_number |   air_time | distance | departure_delay | arrival_delay |  scheduled_departure_time |    scheduled_arrival_time |
| ------:| ------:| -------:| -----------:| -----------:| ----------:| --------:| ---------------:| -------------:| -------------------------:| -------------------------:|
|   1545 |    EWR |      UA |         IAH |      N14228 | 227 minute |  1400 mi |        2 minute |     11 minute | 2013-01-01T05:15:00-05:00 | 2013-01-01T08:19:00-06:00 |
|   1696 |    EWR |      UA |         ORD |      N39463 | 150 minute |   719 mi |       -4 minute |     12 minute | 2013-01-01T05:58:00-05:00 | 2013-01-01T07:28:00-06:00 |
```

We're interested in `visibility` and `departure_delay`. We have one row of weather data on the left but multiple flights on the right. Thus, for each flight, we will need to add in the weather data we are interested in.

```jldoctest flights
julia> visibility = weather.visibility;

julia> over(flights_value, @_ (
            visibility = visibility,
            departure_delay = _.departure_delay
        )) |>
        Peek
| visibility | departure_delay |
| ----------:| ---------------:|
|    10.0 mi |        2 minute |
|    10.0 mi |       -4 minute |
```

We will need to conduct these steps for each match. So put them together into a function.

```jldoctest flights
julia> function interested_in(a_match)
            weather, (flights_key, flights_value) = a_match
            visibility = weather.visibility
            over(flights_value, @_ (
                visibility = visibility,
                departure_delay = _.departure_delay
            ))
        end;

julia> Peek(interested_in(a_match))
| visibility | departure_delay |
| ----------:| ---------------:|
|    10.0 mi |        2 minute |
|    10.0 mi |       -4 minute |
```

For each match, we are returning several rows. Use `Base.Iterators.flatten` to unnest data and get a single iterator of rows. Collect the result.

```jldoctest flights
julia> data =
        @> weathers_to_flights |>
        over(_, interested_in) |>
        flatten |>
        make_columns |>
        Rows(; _...);

julia> Peek(data)
Showing 4 of 326993 rows
| visibility | departure_delay |
| ----------:| ---------------:|
|    10.0 mi |        2 minute |
|    10.0 mi |       -4 minute |
|    10.0 mi |       -5 minute |
|    10.0 mi |       -2 minute |
```

## Visibility vs. departure delay

Now we can finally answer the question we are interested in. How does visibility affect `departure_delay`? First, let's group by visibility.

```jldoctest flights
julia> by_visibility =
        @> data |>
        order(_, name"visibility") |>
        Group(By(_, name"visibility"));

julia> visibility_group = first(by_visibility);

julia> key(visibility_group)
0.0 mi

julia> value(visibility_group) |> Peek
Showing 4 of 87 rows
| visibility | departure_delay |
| ----------:| ---------------:|
|     0.0 mi |       -5 minute |
|     0.0 mi |       -1 minute |
|     0.0 mi |       -8 minute |
|     0.0 mi |       -7 minute |
```

For each group, we can calculate the mean `departure_delay`.

```jldoctest flights
julia> using Statistics: mean

julia> @> visibility_group |>
        value |>
        over(_, name"departure_delay") |>
        mean
32.252873563218394 minute
```

Now run it for all the groups.

```jldoctest flights
julia> get_mean_departure_delay(visibility_group) = (
            visibility = key(visibility_group),
            mean_departure_delay =
                (@> visibility_group |>
                    value |>
                    over(_, name"departure_delay") |>
                    mean),
            count = length(value(visibility_group))
        );

julia> @> by_visibility |>
            over(_, get_mean_departure_delay) |>
            Peek(_, 20)
Showing at most 20 rows
| visibility |      mean_departure_delay |  count |
| ----------:| -------------------------:| ------:|
|     0.0 mi | 32.252873563218394 minute |     87 |
|    0.06 mi |               22.2 minute |     85 |
|    0.12 mi |  50.69975186104218 minute |    403 |
|    0.25 mi | 20.481110254433307 minute |   1297 |
|     0.5 mi |   32.5890826383624 minute |   1319 |
|    0.75 mi |  30.06759906759907 minute |    429 |
|     1.0 mi |  32.24348473566642 minute |   1343 |
|    1.25 mi | 53.187845303867405 minute |    181 |
|     1.5 mi |  25.90661478599222 minute |   1542 |
|    1.75 mi | 43.333333333333336 minute |    132 |
|     2.0 mi | 22.701923076923077 minute |   2912 |
|     2.5 mi |  21.18074398249453 minute |   2285 |
|     3.0 mi |   21.2113218731476 minute |   3374 |
|     4.0 mi |  19.48311444652908 minute |   2132 |
|     5.0 mi |  21.10387902695595 minute |   4563 |
|     6.0 mi | 19.807032301480483 minute |   5944 |
|     7.0 mi | 19.208963745361118 minute |   7006 |
|     8.0 mi |  19.98660103910309 minute |   7314 |
|     9.0 mi | 18.762949476558944 minute |  10985 |
|    10.0 mi | 10.951549367828692 minute | 273660 |
```

This data suggests that low visibility levels lead to larger departure delays, on average.
