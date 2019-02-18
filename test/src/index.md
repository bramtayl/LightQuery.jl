# Tutorial

I'm going to use the flights data from the
[dplyr tutorial](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html).
This data is in the test folder of this package. I re-export
[`CSV`](http://juliadata.github.io/CSV.jl/stable/) for input-output.

```jldoctest dplyr
julia> using LightQuery

julia> airports_file = CSV.File("airports.csv", allowmissing = :auto)
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

`allowmissing = :auto` tells CSV to guess whether columns might contain misisng
data.

Let's take a look at the first row. Use [`named_tuple`](@ref) to coerce a
`CSV.Row` to a `NamedTuple`. I'm going to make heavy use of the chaining macro
[`@>`](@ref) and lazy call macro [`@_`](@ref).

```jldoctest dplyr
julia> airport =
        @> airports_file |>
        first |>
        named_tuple
(faa = "04G", name = "Lansdowne Airport", lat = 41.1304722, lon = -80.6195833, alt = 1044, tz = -5, dst = "A", tzone = "America/New_York")
```

As a start, I want to rename so that I understand what the columns mean. When
you [`rename`](@ref), names need to be wrapped with [`Name`](@ref).

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

Let's create a proper `TimeZone`, and add units to our variables.

```jldoctest dplyr
julia> using TimeZones: VariableTimeZone, TimeZone

julia> using Unitful: °, ft

julia> airport =
        @> airport |>
        transform(_,
            time_zone = TimeZone(_.time_zone),
            latitude = _.latitude * °,
            longitude = _.longitude * °,
            altitude = _.altitude * ft
        )
(name = "Lansdowne Airport", airport_code = "04G", latitude = 41.1304722°, longitude = -80.6195833°, altitude = 1044 ft, time_zone_offset = -5, daylight_savings = "A", time_zone = America/New_York (UTC-5/UTC-4))
```

Now that we have a true timezone, we can remove all data that is
contingent on timezone.

```jldoctest dplyr
julia> airport =
        @> airport |>
        remove(_,
            :time_zone_offset,
            :daylight_savings
        )
(name = "Lansdowne Airport", airport_code = "04G", latitude = 41.1304722°, longitude = -80.6195833°, altitude = 1044 ft, time_zone = America/New_York (UTC-5/UTC-4))
```

Notice that we know that there will be one entry for each airport code. This
signals that this data might be best stored as a `Dict`. Let's put everything
together:

```jldoctest dplyr
julia> const airports = Dict(
            airport.airport_code => remove(airport, :airport_code)
        )
Dict{String,NamedTuple{(:name, :latitude, :longitude, :altitude, :time_zone),Tuple{String,Unitful.Quantity{Float64,NoDims,Unitful.FreeUnits{(°,),NoDims,nothing}},Unitful.Quantity{Float64,NoDims,Unitful.FreeUnits{(°,),NoDims,nothing}},Unitful.Quantity{Int64,𝐋,Unitful.FreeUnits{(ft,),𝐋,nothing}},VariableTimeZone}}} with 1 entry:
  "04G" => (name = "Lansdowne Airport", latitude = 41.1305°, longitude = -80.61…

julia> function process_airport(airport_row)
            airport =
                @> named_tuple(airport_row) |>
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
                    time_zone = TimeZone(_.time_zone),
                    latitude = _.latitude * °,
                    longitude = _.longitude * °,
                    altitude = _.altitude * ft
                ) |>
                remove(_,
                    :time_zone_offset,
                    :daylight_savings
                )
            airports[airport.airport_code] = remove(airport, :airport_code)
        end
process_airport (generic function with 1 method)

julia> foreach(process_airport, airports_file)
ERROR: ArgumentError: Unknown time zone "Asia/Chongqing"
```

Uh oh. A bit of googling shows that "Asia/Chongqing" is an alias for
"Asia/Shanghai". Try again.

```jldoctest dplyr
julia> function process_airport(airport_row)
            airport =
                @> named_tuple(airport_row) |>
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
                    time_zone = TimeZone(
                        if _.time_zone == "Asia/Chongqing"
                            "Asia/Shanghai"
                        else
                            _.time_zone
                        end
                    ),
                    latitude = _.latitude * °,
                    longitude = _.longitude * °,
                    altitude = _.altitude * ft
                ) |>
                remove(_,
                    :time_zone_offset,
                    :daylight_savings
                )
            airports[airport.airport_code] = remove(airport, :airport_code)
            nothing
        end
process_airport (generic function with 1 method)

julia> foreach(process_airport, airports_file)
ERROR: ArgumentError: Unknown time zone "\N"
```

Hadley, you're killing me. "\\N" is definitely not a timezone. I'm not in the
mood for playing games; let's just ignore those airports. I use [`when`](@ref)
to lazily filter aiports.

```jldoctest dplyr
julia> @> airports_file |>
        when(_, @_ _.tzone != "\\N") |>
        foreach(process_airport, _)
```

We did it! That was just the warm-up. Now let's get started working on the
flights data.

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
        named_tuple(_)
(year = 2013, month = 1, day = 1, dep_time = 517, sched_dep_time = 515, dep_delay = 2, arr_time = 830, sched_arr_time = 819, arr_delay = 11, carrier = "UA", flight = 1545, tailnum = "N14228", origin = "EWR", dest = "IAH", air_time = 227, distance = 1400, hour = 5, minute = 15, time_hour = "2013-01-01 05:00:00")
```

Again, some renaming:

```jldoctest dplyr
julia> flight =
        @> flight |>
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
julia> using Dates: DateTime

julia> using TimeZones: ZonedDateTime

julia> scheduled_departure_time = ZonedDateTime(
            DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),
            airports[flight.origin].time_zone
        )
2013-01-01T05:15:00-05:00
```

Note the scheduled arrival time is `818`. This means `8:18`. We can use
`divrem(_, 100)` to split it up.

```jldoctest dplyr
julia> scheduled_arrival_time = ZonedDateTime(
            DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),
            airports[flight.destination].time_zone
        )
2013-01-01T08:19:00-06:00
```

What if it was an over-night flight? We can add a day to the arrival time if
it wasn't later than the departure time.

```jldoctest dplyr
julia> using Dates: Day

julia> if !(scheduled_arrival_time > scheduled_departure_time)
            scheduled_arrival_time = scheduled_arrival_time + Day(1)
        end
```

Now let's add the data back into our flight, and remove redundant columns.

```jldoctest dplyr
julia> flight =
        @> flight |>
        transform(_,
            scheduled_departure_time = scheduled_departure_time,
            scheduled_arrival_time = scheduled_arrival_time
        ) |>
        remove(_, :year, :month, :day, :hour, :minute, :time_hour,
            :departure_time, :arrival_time)
(carrier = "UA", flight = 1545, origin = "EWR", air_time = 227, distance = 1400, scheduled_departure_time = 2013-01-01T05:15:00-05:00, departure_delay = 2, scheduled_arrival_time = 2013-01-01T08:19:00-06:00, arrival_delay = 11, tail_number = "N14228", destination = "IAH")
```

Now let's add in some units:

```jldoctest dplyr
julia> using Dates: Minute

julia> using Unitful: mi

julia> flight =
        @> flight |>
        transform(_,
            air_time = Minute(_.air_time),
            distance = _.distance * mi,
            departure_delay = Minute(_.departure_delay),
            arrival_delay = Minute(_.arrival_delay)
        )
(carrier = "UA", flight = 1545, origin = "EWR", air_time = Minute(227), distance = 1400 mi, scheduled_departure_time = 2013-01-01T05:15:00-05:00, departure_delay = Minute(2), scheduled_arrival_time = 2013-01-01T08:19:00-06:00, arrival_delay = Minute(11), tail_number = "N14228", destination = "IAH")
```

Put it all together. I'm conducting some mild type piracy to get `Minute` to work
with missing data. When it comes time to collect, I'm calling
[`make_columns`](@ref) then [`rows`](@ref). It makes sense to store this data
column-wise. This is because there are multiple columns that might contain
missing data. I use [`over`](@ref) to lazily `map`. Note that I'm only
considering flights with corresponding airport data.

```jldoctest dplyr
julia> import Dates: Minute

julia> Minute(::Missing) = missing
Minute

julia> function process_flight(row)
            flight =
                @> named_tuple(row) |>
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
                airports[flight.destination].time_zone
            )
            if !(scheduled_arrival_time > scheduled_departure_time)
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
        end
process_flight (generic function with 1 method)

julia> flights =
        @> flights_file |>
        when(_, @_ haskey(airports, _.origin) && haskey(airports, _.dest)) |>
        over(_, process_flight) |>
        make_columns |>
        rows;

julia> Peek(flights)
Showing 4 of 329174 rows
| :carrier | :flight | :origin |   :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |
| --------:| -------:| -------:| -----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|
|       UA |    1545 |     EWR | 227 minutes |   1400 mi | 2013-01-01T05:15:00-05:00 |        2 minutes | 2013-01-01T08:19:00-06:00 |     11 minutes |       N14228 |          IAH |
|       UA |    1714 |     LGA | 227 minutes |   1416 mi | 2013-01-01T05:29:00-05:00 |        4 minutes | 2013-01-01T08:30:00-06:00 |     20 minutes |       N24211 |          IAH |
|       AA |    1141 |     JFK | 160 minutes |   1089 mi | 2013-01-01T05:40:00-05:00 |        2 minutes | 2013-01-01T08:50:00-05:00 |     33 minutes |       N619AA |          MIA |
|       DL |     461 |     LGA | 116 minutes |    762 mi | 2013-01-01T06:00:00-05:00 |       -6 minutes | 2013-01-01T08:37:00-05:00 |    -25 minutes |       N668DN |          ATL |
```

You might notice that if the origin and the destination are the same, then the
distance is also the same. We can see this by [`order`](@ref) ing the data.
Note that [`Names`](@ref) can be used as a function to select columns.

```jldoctest dplyr
julia> by_path =
        @> flights |>
        order(_, Names(:origin, :destination));

julia> Peek(by_path)
Showing 4 of 329174 rows
| :carrier | :flight | :origin |  :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |
| --------:| -------:| -------:| ----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|
|       EV |    4112 |     EWR | 33 minutes |    143 mi | 2013-01-01T13:17:00-05:00 |       -2 minutes | 2013-01-01T14:23:00-05:00 |    -10 minutes |       N13538 |          ALB |
|       EV |    3260 |     EWR | 36 minutes |    143 mi | 2013-01-01T16:21:00-05:00 |       34 minutes | 2013-01-01T17:24:00-05:00 |     40 minutes |       N19554 |          ALB |
|       EV |    4170 |     EWR | 31 minutes |    143 mi | 2013-01-01T20:04:00-05:00 |       52 minutes | 2013-01-01T21:12:00-05:00 |     44 minutes |       N12540 |          ALB |
|       EV |    4316 |     EWR | 33 minutes |    143 mi | 2013-01-02T13:27:00-05:00 |        5 minutes | 2013-01-02T14:33:00-05:00 |    -14 minutes |       N14153 |          ALB |
```

How can we remove this redundant information from our dataset? Let's make a
distances dataset.

```jldoctest dplyr
julia> const distances = Dict(
            Names(:origin, :destination)(flight) => flight.distance
        )
Dict{NamedTuple{(:origin, :destination),Tuple{String,String}},Unitful.Quantity{Int64,𝐋,Unitful.FreeUnits{(mi,),𝐋,nothing}}} with 1 entry:
  (origin = "EWR", destination = "IAH") => 1400 mi
```

Now we can [`Group`](@ref) our flights data [`By`](@ref) the path. Each group
will be a [`key`](@ref) (the origin and destination) mapped to a [`value`](@ref)
(a sub-table). We can group the already sorted data.

```jldoctest dplyr
julia> @> by_path |>
        Group(By(_, Names(:origin, :destination))) |>
        foreach((@_ distances[key(_)] = first(value(_)).distance), _)
```

We can drop the distance variable from flights now. To do this efficiently, we
use [`columns`](@ref), which is always lazy.

```jldoctest dplyr
julia> flights =
        @> flights |>
        columns |>
        remove(_, :distance) |>
        rows;
```

Let's take a look at all of our beautiful data!

```jldoctest dplyr
julia> Peek(airports)
Showing 4 of 1455 rows
| :first |                                                                                                                                             :second |
| ------:| ---------------------------------------------------------------------------------------------------------------------------------------------------:|
|    JES |  (name = "Jesup-Wayne County Airport", latitude = 31.553889°, longitude = -81.8825°, altitude = 107 ft, time_zone = America/New_York (UTC-5/UTC-4)) |
|    PPV | (name = "Port Protection Seaplane Base", latitude = 56.328889°, longitude = -133.61°, altitude = 0 ft, time_zone = America/Anchorage (UTC-9/UTC-8)) |
|    DTA | (name = "Delta Municipal Airport", latitude = 39.3806386°, longitude = -112.5077147°, altitude = 4759 ft, time_zone = America/Denver (UTC-7/UTC-6)) |
|    X21 |         (name = "Arthur Dunn Airpark", latitude = 28.622552°, longitude = -80.83541°, altitude = 30 ft, time_zone = America/New_York (UTC-5/UTC-4)) |

julia> Peek(flights)
Showing 4 of 329174 rows
| :carrier | :flight | :origin |   :air_time | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |
| --------:| -------:| -------:| -----------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|
|       UA |    1545 |     EWR | 227 minutes | 2013-01-01T05:15:00-05:00 |        2 minutes | 2013-01-01T08:19:00-06:00 |     11 minutes |       N14228 |          IAH |
|       UA |    1714 |     LGA | 227 minutes | 2013-01-01T05:29:00-05:00 |        4 minutes | 2013-01-01T08:30:00-06:00 |     20 minutes |       N24211 |          IAH |
|       AA |    1141 |     JFK | 160 minutes | 2013-01-01T05:40:00-05:00 |        2 minutes | 2013-01-01T08:50:00-05:00 |     33 minutes |       N619AA |          MIA |
|       DL |     461 |     LGA | 116 minutes | 2013-01-01T06:00:00-05:00 |       -6 minutes | 2013-01-01T08:37:00-05:00 |    -25 minutes |       N668DN |          ATL |

julia> Peek(distances)
Showing 4 of 217 rows
|                                :first | :second |
| -------------------------------------:| -------:|
| (origin = "LGA", destination = "PHL") |   96 mi |
| (origin = "JFK", destination = "SAN") | 2446 mi |
| (origin = "EWR", destination = "MSY") | 1167 mi |
| (origin = "JFK", destination = "MSY") | 1182 mi |
```

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
over
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
