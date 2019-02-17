var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "page",
    "text": ""
},

{
    "location": "#Tutorial-1",
    "page": "Tutorial",
    "title": "Tutorial",
    "category": "section",
    "text": "I\'m going to use the flights data from the dplyr tutorial. This data is in the test folder of this package. I re-export CSV for input-output.julia> using LightQuery\n\njulia> airports_file = CSV.File(\"airports.csv\", allowmissing = :auto)\nCSV.File(\"airports.csv\", rows=1458):\nTables.Schema:\n :faa    String\n :name   String\n :lat    Float64\n :lon    Float64\n :alt    Int64\n :tz     Int64\n :dst    String\n :tzone  Stringallowmissing = :auto tells CSV to guess whether columns might contain misisng data.Let\'s take a look at the first row. Use named_tuple to coerce a CSV.Row to a NamedTuple. I\'m going to make heavy use of the chaining macro @> and lazy call macro @_.julia> airport =\n        @> airports_file |>\n        first |>\n        named_tuple\n(faa = \"04G\", name = \"Lansdowne Airport\", lat = 41.1304722, lon = -80.6195833, alt = 1044, tz = -5, dst = \"A\", tzone = \"America/New_York\")As a start, I want to rename so that I understand what the columns mean. When you rename, names need to be wrapped with Name.julia> airport =\n        @> airport |>\n        rename(_,\n            airport_code = Name(:faa),\n            latitude = Name(:lat),\n            longitude = Name(:lon),\n            altitude = Name(:alt),\n            time_zone_offset = Name(:tz),\n            daylight_savings = Name(:dst),\n            time_zone = Name(:tzone)\n        )\n(name = \"Lansdowne Airport\", airport_code = \"04G\", latitude = 41.1304722, longitude = -80.6195833, altitude = 1044, time_zone_offset = -5, daylight_savings = \"A\", time_zone = \"America/New_York\")Let\'s create a proper TimeZone, and add units to our variables.julia> using TimeZones: VariableTimeZone, TimeZone\n\njulia> using Unitful: °, ft\n\njulia> airport =\n        @> airport |>\n        transform(_,\n            time_zone = TimeZone(_.time_zone),\n            latitude = _.latitude * °,\n            longitude = _.longitude * °,\n            altitude = _.altitude * ft\n        )\n(name = \"Lansdowne Airport\", airport_code = \"04G\", latitude = 41.1304722°, longitude = -80.6195833°, altitude = 1044 ft, time_zone_offset = -5, daylight_savings = \"A\", time_zone = America/New_York (UTC-5/UTC-4))Now that we have a true timezone, we can remove all data that is contingent on timezone.julia> airport =\n        @> airport |>\n        remove(_,\n            :time_zone_offset,\n            :daylight_savings\n        )\n(name = \"Lansdowne Airport\", airport_code = \"04G\", latitude = 41.1304722°, longitude = -80.6195833°, altitude = 1044 ft, time_zone = America/New_York (UTC-5/UTC-4))Notice that we know that there will be one entry for each airport code. This signals that this data might be best stored as a Dict. Let\'s put everything together:julia> const airports = Dict(\n            airport.airport_code => remove(airport, :airport_code)\n        )\nDict{String,NamedTuple{(:name, :latitude, :longitude, :altitude, :time_zone),Tuple{String,Unitful.Quantity{Float64,NoDims,Unitful.FreeUnits{(°,),NoDims,nothing}},Unitful.Quantity{Float64,NoDims,Unitful.FreeUnits{(°,),NoDims,nothing}},Unitful.Quantity{Int64,𝐋,Unitful.FreeUnits{(ft,),𝐋,nothing}},VariableTimeZone}}} with 1 entry:\n  \"04G\" => (name = \"Lansdowne Airport\", latitude = 41.1305°, longitude = -80.61…\n\njulia> function process_airport(airport_row)\n            airport =\n                @> named_tuple(airport_row) |>\n                rename(_,\n                    airport_code = Name(:faa),\n                    latitude = Name(:lat),\n                    longitude = Name(:lon),\n                    altitude = Name(:alt),\n                    time_zone_offset = Name(:tz),\n                    daylight_savings = Name(:dst),\n                    time_zone = Name(:tzone)\n                ) |>\n                transform(_,\n                    time_zone = TimeZone(_.time_zone),\n                    latitude = _.latitude * °,\n                    longitude = _.longitude * °,\n                    altitude = _.altitude * ft\n                ) |>\n                remove(_,\n                    :time_zone_offset,\n                    :daylight_savings\n                )\n            airports[airport.airport_code] = remove(airport, :airport_code)\n        end\nprocess_airport (generic function with 1 method)\n\njulia> foreach(process_airport, airports_file)\nERROR: ArgumentError: Unknown time zone \"Asia/Chongqing\"Uh oh. A bit of googling shows that \"Asia/Chongqing\" is an alias for \"Asia/Shanghai\". Try again.julia> function process_airport(airport_row)\n            airport =\n                @> named_tuple(airport_row) |>\n                rename(_,\n                    airport_code = Name(:faa),\n                    latitude = Name(:lat),\n                    longitude = Name(:lon),\n                    altitude = Name(:alt),\n                    time_zone_offset = Name(:tz),\n                    daylight_savings = Name(:dst),\n                    time_zone = Name(:tzone)\n                ) |>\n                transform(_,\n                    time_zone = TimeZone(\n                        if _.time_zone == \"Asia/Chongqing\"\n                            \"Asia/Shanghai\"\n                        else\n                            _.time_zone\n                        end\n                    ),\n                    latitude = _.latitude * °,\n                    longitude = _.longitude * °,\n                    altitude = _.altitude * ft\n                ) |>\n                remove(_,\n                    :time_zone_offset,\n                    :daylight_savings\n                )\n            airports[airport.airport_code] = remove(airport, :airport_code)\n            nothing\n        end\nprocess_airport (generic function with 1 method)\n\njulia> foreach(process_airport, airports_file)\nERROR: ArgumentError: Unknown time zone \"\\N\"Hadley, you\'re killing me. \"\\N\" is definitely not a timezone. I\'m not in the mood for playing games; let\'s just ignore those airports. I use when to lazily filter aiports.julia> @> airports_file |>\n        when(_, @_ _.tzone != \"\\\\N\") |>\n        foreach(process_airport, _)We did it! That was just the warm-up. Now let\'s get started working on the flights data.julia> flights_file = CSV.File(\"flights.csv\", allowmissing = :auto)\nCSV.File(\"flights.csv\", rows=336776):\nTables.Schema:\n :year            Int64\n :month           Int64\n :day             Int64\n :dep_time        Union{Missing, Int64}\n :sched_dep_time  Int64\n :dep_delay       Union{Missing, Int64}\n :arr_time        Union{Missing, Int64}\n :sched_arr_time  Int64\n :arr_delay       Union{Missing, Int64}\n :carrier         String\n :flight          Int64\n :tailnum         Union{Missing, String}\n :origin          String\n :dest            String\n :air_time        Union{Missing, Int64}\n :distance        Int64\n :hour            Int64\n :minute          Int64\n :time_hour       String\n\njulia> flight =\n        @> flights_file |>\n        first |>\n        named_tuple(_)\n(year = 2013, month = 1, day = 1, dep_time = 517, sched_dep_time = 515, dep_delay = 2, arr_time = 830, sched_arr_time = 819, arr_delay = 11, carrier = \"UA\", flight = 1545, tailnum = \"N14228\", origin = \"EWR\", dest = \"IAH\", air_time = 227, distance = 1400, hour = 5, minute = 15, time_hour = \"2013-01-01 05:00:00\")Again, some renaming:julia> flight =\n        @> flight |>\n        rename(_,\n            departure_time = Name(:dep_time),\n            scheduled_departure_time = Name(:sched_dep_time),\n            departure_delay = Name(:dep_delay),\n            arrival_time = Name(:arr_time),\n            scheduled_arrival_time = Name(:sched_arr_time),\n            arrival_delay = Name(:arr_delay),\n            tail_number = Name(:tailnum),\n            destination = Name(:dest)\n        )\n(year = 2013, month = 1, day = 1, carrier = \"UA\", flight = 1545, origin = \"EWR\", air_time = 227, distance = 1400, hour = 5, minute = 15, time_hour = \"2013-01-01 05:00:00\", departure_time = 517, scheduled_departure_time = 515, departure_delay = 2, arrival_time = 830, scheduled_arrival_time = 819, arrival_delay = 11, tail_number = \"N14228\", destination = \"IAH\")We can use our airports data to make datetimes with timezones.julia> using Dates: DateTime\n\njulia> using TimeZones: ZonedDateTime\n\njulia> scheduled_departure_time = ZonedDateTime(\n            DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),\n            airports[flight.origin].time_zone\n        )\n2013-01-01T05:15:00-05:00Note the scheduled arrival time is 818. This means 8:18. We can use divrem(_, 100) to split it up.julia> scheduled_arrival_time = ZonedDateTime(\n            DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),\n            airports[flight.destination].time_zone\n        )\n2013-01-01T08:19:00-06:00What if it was an over-night flight? We can add a day to the arrival time if it wasn\'t later than the departure time.julia> using Dates: Day\n\njulia> if !(scheduled_arrival_time > scheduled_departure_time)\n            scheduled_arrival_time = scheduled_arrival_time + Day(1)\n        endNow let\'s add the data back into our flight, and remove redundant columns.julia> flight =\n        @> flight |>\n        transform(_,\n            scheduled_departure_time = scheduled_departure_time,\n            scheduled_arrival_time = scheduled_arrival_time\n        ) |>\n        remove(_, :year, :month, :day, :hour, :minute, :time_hour,\n            :departure_time, :arrival_time)\n(carrier = \"UA\", flight = 1545, origin = \"EWR\", air_time = 227, distance = 1400, scheduled_departure_time = 2013-01-01T05:15:00-05:00, departure_delay = 2, scheduled_arrival_time = 2013-01-01T08:19:00-06:00, arrival_delay = 11, tail_number = \"N14228\", destination = \"IAH\")Now let\'s add in some units:julia> using Dates: Minute\n\njulia> using Unitful: mi\n\njulia> flight =\n        @> flight |>\n        transform(_,\n            air_time = Minute(_.air_time),\n            distance = _.distance * mi,\n            departure_delay = Minute(_.departure_delay),\n            arrival_delay = Minute(_.arrival_delay)\n        )\n(carrier = \"UA\", flight = 1545, origin = \"EWR\", air_time = Minute(227), distance = 1400 mi, scheduled_departure_time = 2013-01-01T05:15:00-05:00, departure_delay = Minute(2), scheduled_arrival_time = 2013-01-01T08:19:00-06:00, arrival_delay = Minute(11), tail_number = \"N14228\", destination = \"IAH\")Put it all together. I\'m conducting some mild type piracy to get Minute to work with missing data. When it comes time to collect, I\'m calling make_columns then rows. It makes sense to store this data column-wise. This is because there are multiple columns that might contain missing data. I use over to lazily map. Note that I\'m only considering flights with corresponding airport data.julia> import Dates: Minute\n\njulia> Minute(::Missing) = missing\nMinute\n\njulia> function process_flight(row)\n            flight =\n                @> named_tuple(row) |>\n                rename(_,\n                    departure_time = Name(:dep_time),\n                    scheduled_departure_time = Name(:sched_dep_time),\n                    departure_delay = Name(:dep_delay),\n                    arrival_time = Name(:arr_time),\n                    scheduled_arrival_time = Name(:sched_arr_time),\n                    arrival_delay = Name(:arr_delay),\n                    tail_number = Name(:tailnum),\n                    destination = Name(:dest)\n                )\n            scheduled_departure_time = ZonedDateTime(\n                DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),\n                airports[flight.origin].time_zone\n            )\n            scheduled_arrival_time = ZonedDateTime(\n                DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),\n                airports[flight.destination].time_zone\n            )\n            if !(scheduled_arrival_time > scheduled_departure_time)\n                scheduled_arrival_time = scheduled_arrival_time + Day(1)\n            end\n            @> flight |>\n                transform(_,\n                    scheduled_departure_time = scheduled_departure_time,\n                    scheduled_arrival_time = scheduled_arrival_time,\n                    air_time = Minute(_.air_time),\n                    distance = _.distance * mi,\n                    departure_delay = Minute(_.departure_delay),\n                    arrival_delay = Minute(_.arrival_delay)\n                ) |>\n                remove(_, :year, :month, :day, :hour, :minute, :time_hour,\n                    :departure_time, :arrival_time)\n        end\nprocess_flight (generic function with 1 method)\n\njulia> flights =\n        @> flights_file |>\n        when(_, @_ haskey(airports, _.origin) && haskey(airports, _.dest)) |>\n        over(_, process_flight) |>\n        make_columns |>\n        rows;\n\njulia> Peek(flights)\nShowing 4 of 329174 rows\n| :carrier | :flight | :origin |   :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |\n| --------:| -------:| -------:| -----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|\n|       UA |    1545 |     EWR | 227 minutes |   1400 mi | 2013-01-01T05:15:00-05:00 |        2 minutes | 2013-01-01T08:19:00-06:00 |     11 minutes |       N14228 |          IAH |\n|       UA |    1714 |     LGA | 227 minutes |   1416 mi | 2013-01-01T05:29:00-05:00 |        4 minutes | 2013-01-01T08:30:00-06:00 |     20 minutes |       N24211 |          IAH |\n|       AA |    1141 |     JFK | 160 minutes |   1089 mi | 2013-01-01T05:40:00-05:00 |        2 minutes | 2013-01-01T08:50:00-05:00 |     33 minutes |       N619AA |          MIA |\n|       DL |     461 |     LGA | 116 minutes |    762 mi | 2013-01-01T06:00:00-05:00 |       -6 minutes | 2013-01-01T08:37:00-05:00 |    -25 minutes |       N668DN |          ATL |You might notice that if the origin and the destination are the same, then the distance is also the same. We can see this by order ing the data.julia> by_path =\n        @> flights |>\n        order(_, Names(:origin, :destination));\n\njulia> Peek(by_path)\nShowing 4 of 329174 rows\n| :carrier | :flight | :origin |  :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |\n| --------:| -------:| -------:| ----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|\n|       EV |    4112 |     EWR | 33 minutes |    143 mi | 2013-01-01T13:17:00-05:00 |       -2 minutes | 2013-01-01T14:23:00-05:00 |    -10 minutes |       N13538 |          ALB |\n|       EV |    3260 |     EWR | 36 minutes |    143 mi | 2013-01-01T16:21:00-05:00 |       34 minutes | 2013-01-01T17:24:00-05:00 |     40 minutes |       N19554 |          ALB |\n|       EV |    4170 |     EWR | 31 minutes |    143 mi | 2013-01-01T20:04:00-05:00 |       52 minutes | 2013-01-01T21:12:00-05:00 |     44 minutes |       N12540 |          ALB |\n|       EV |    4316 |     EWR | 33 minutes |    143 mi | 2013-01-02T13:27:00-05:00 |        5 minutes | 2013-01-02T14:33:00-05:00 |    -14 minutes |       N14153 |          ALB |How can we remove this redundant information from our dataset? Let\'s make a distances dataset.julia> const distances = Dict(\n            Names(:origin, :destination)(flight) => flight.distance\n        )\nDict{NamedTuple{(:origin, :destination),Tuple{String,String}},Unitful.Quantity{Int64,𝐋,Unitful.FreeUnits{(mi,),𝐋,nothing}}} with 1 entry:\n  (origin = \"EWR\", destination = \"IAH\") => 1400 miNow we can Group our flights data By the path. Each group will be a key (the origin and destination) mapped to a value (a sub-table). We can group the already sorted data.julia> @> by_path |>\n        Group(By(_, Names(:origin, :destination))) |>\n        foreach((@_ distances[key(_)] = first(value(_)).distance), _)We can drop the distance variable from flights now. To do this efficiently, we use columns, which is always lazy.julia> flights =\n        @> flights |>\n        columns |>\n        remove(_, :distance) |>\n        rows;Let\'s take a look at all of our beautiful data!julia> Peek(airports)\nShowing 4 of 1455 rows\n| :first |                                                                                                                                             :second |\n| ------:| ---------------------------------------------------------------------------------------------------------------------------------------------------:|\n|    JES |  (name = \"Jesup-Wayne County Airport\", latitude = 31.553889°, longitude = -81.8825°, altitude = 107 ft, time_zone = America/New_York (UTC-5/UTC-4)) |\n|    PPV | (name = \"Port Protection Seaplane Base\", latitude = 56.328889°, longitude = -133.61°, altitude = 0 ft, time_zone = America/Anchorage (UTC-9/UTC-8)) |\n|    DTA | (name = \"Delta Municipal Airport\", latitude = 39.3806386°, longitude = -112.5077147°, altitude = 4759 ft, time_zone = America/Denver (UTC-7/UTC-6)) |\n|    X21 |         (name = \"Arthur Dunn Airpark\", latitude = 28.622552°, longitude = -80.83541°, altitude = 30 ft, time_zone = America/New_York (UTC-5/UTC-4)) |\n\njulia> Peek(flights)\nShowing 4 of 329174 rows\n| :carrier | :flight | :origin |   :air_time | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |\n| --------:| -------:| -------:| -----------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|\n|       UA |    1545 |     EWR | 227 minutes | 2013-01-01T05:15:00-05:00 |        2 minutes | 2013-01-01T08:19:00-06:00 |     11 minutes |       N14228 |          IAH |\n|       UA |    1714 |     LGA | 227 minutes | 2013-01-01T05:29:00-05:00 |        4 minutes | 2013-01-01T08:30:00-06:00 |     20 minutes |       N24211 |          IAH |\n|       AA |    1141 |     JFK | 160 minutes | 2013-01-01T05:40:00-05:00 |        2 minutes | 2013-01-01T08:50:00-05:00 |     33 minutes |       N619AA |          MIA |\n|       DL |     461 |     LGA | 116 minutes | 2013-01-01T06:00:00-05:00 |       -6 minutes | 2013-01-01T08:37:00-05:00 |    -25 minutes |       N668DN |          ATL |\n\njulia> Peek(distances)\nShowing 4 of 217 rows\n|                                :first | :second |\n| -------------------------------------:| -------:|\n| (origin = \"LGA\", destination = \"PHL\") |   96 mi |\n| (origin = \"JFK\", destination = \"SAN\") | 2446 mi |\n| (origin = \"EWR\", destination = \"MSY\") | 1167 mi |\n| (origin = \"JFK\", destination = \"MSY\") | 1182 mi |"
},

{
    "location": "#Interface-1",
    "page": "Tutorial",
    "title": "Interface",
    "category": "section",
    "text": ""
},

{
    "location": "#LightQuery.@_",
    "page": "Tutorial",
    "title": "LightQuery.@_",
    "category": "macro",
    "text": "macro _(body)\n\nTerser function syntax. The arguments are inside the body; the first argument is _, the second argument is __, etc. Will always @inline.\n\njulia> using LightQuery\n\njulia> (@_ _ + 1)(1)\n2\n\njulia> map((@_ __ - _), (1, 2), (2, 1))\n(1, -1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@>",
    "page": "Tutorial",
    "title": "LightQuery.@>",
    "category": "macro",
    "text": "macro >(body)\n\nIf body is in the form body_ |> tail_, call @_ on tail, and recur on body.\n\njulia> using LightQuery\n\njulia> @> 0 |> _ - 1 |> abs\n1\n\n\n\n\n\n"
},

{
    "location": "#Macros-1",
    "page": "Tutorial",
    "title": "Macros",
    "category": "section",
    "text": "@_\n@>"
},

{
    "location": "#LightQuery.named_tuple",
    "page": "Tutorial",
    "title": "LightQuery.named_tuple",
    "category": "function",
    "text": "named_tuple(it)\n\nCoerce to a named_tuple. For performance with working with arbitrary structs, define and @inline propertynames.\n\njulia> using LightQuery\n\njulia> @inline Base.propertynames(p::Pair) = (:first, :second)\n\njulia> named_tuple(:a => 1)\n(first = :a, second = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Name",
    "page": "Tutorial",
    "title": "LightQuery.Name",
    "category": "type",
    "text": "Name(name)\n\nCreate a typed name. Can be used as a function to getproperty, with a default to missing. For multiple names, see Names.\n\njulia> using LightQuery\n\njulia> (a = 1,) |>\n        Name(:a)\n1\n\njulia> (a = 1,) |>\n        Name(:b)\nmissing\n\njulia> missing |>\n        Name(:a)\nmissing\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Names",
    "page": "Tutorial",
    "title": "LightQuery.Names",
    "category": "type",
    "text": "Names(the_names...)\n\nCreate typed names. Can be used to as a function to assign or select names, with a default to missing. For just one name, see Name.\n\njulia> using LightQuery\n\njulia> (1, 1.0) |>\n        Names(:a, :b)\n(a = 1, b = 1.0)\n\njulia> (a = 1, b = 1.0) |>\n        Names(:a)\n(a = 1,)\n\njulia> (a = 1,) |>\n        Names(:a, :b)\n(a = 1, b = missing)\n\njulia> missing |>\n        Names(:a)\n(a = missing,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rename",
    "page": "Tutorial",
    "title": "LightQuery.rename",
    "category": "function",
    "text": "rename(it; renames...)\n\nRename it. Because constants do not constant propagate through key-word arguments, wrap with Name.\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0) |>\n        rename(_, c = Name(:a))\n(b = 1.0, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.transform",
    "page": "Tutorial",
    "title": "LightQuery.transform",
    "category": "function",
    "text": "transform(it; assignments...)\n\nMerge assignments into it. Inverse of remove.\n\njulia> using LightQuery\n\njulia> @> (a = 1,) |>\n        transform(_, b = 1.0)\n(a = 1, b = 1.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.remove",
    "page": "Tutorial",
    "title": "LightQuery.remove",
    "category": "function",
    "text": "remove(it, the_names...)\n\nRemove the_names. Inverse of transform.\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0) |>\n        remove(_, :b)\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather",
    "page": "Tutorial",
    "title": "LightQuery.gather",
    "category": "function",
    "text": "gather(it; assignments...)\n\nFor each key => value pair in assignments, gather the Names in value into a single key. Inverse of spread.\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0, c = 1//1) |>\n        gather(_, d = Names(:a, :c))\n(b = 1.0, d = (a = 1, c = 1//1))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.spread",
    "page": "Tutorial",
    "title": "LightQuery.spread",
    "category": "function",
    "text": "spread(it::NamedTuple, the_names...)\n\nUnnest nested it in name. Inverse of gather.\n\njulia> using LightQuery\n\njulia> @> (b = 1.0, d = (a = 1, c = 1//1)) |>\n        spread(_, :d)\n(b = 1.0, a = 1, c = 1//1)\n\n\n\n\n\n"
},

{
    "location": "#Columns-1",
    "page": "Tutorial",
    "title": "Columns",
    "category": "section",
    "text": "named_tuple\nName\nNames\nrename\ntransform\nremove\ngather\nspread"
},

{
    "location": "#LightQuery.unzip",
    "page": "Tutorial",
    "title": "LightQuery.unzip",
    "category": "function",
    "text": "unzip(it, n)\n\nUnzip an iterator it which returns tuples of length n. Use Val(n) to guarantee type stability.\n\njulia> using LightQuery\n\njulia> unzip([(1, 1.0), (2, 2.0)], 2)\n([1, 2], [1.0, 2.0])\n\njulia> unzip([(1, 1.0), (2, 2.0)], Val(2))\n([1, 2], [1.0, 2.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.over",
    "page": "Tutorial",
    "title": "LightQuery.over",
    "category": "function",
    "text": "over(it, call)\n\nLazy map with argument order reversed.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.when",
    "page": "Tutorial",
    "title": "LightQuery.when",
    "category": "function",
    "text": "when(it, call)\n\nLazy filter with argument order reversed.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.order",
    "page": "Tutorial",
    "title": "LightQuery.order",
    "category": "function",
    "text": "order(it, call; keywords...)\norder(it, call, condition; keywords...)\n\nGeneralized sort. keywords will be passed to sort!; see the documentation there for options. See By for a way to explicitly mark that an object has been sorted. Most performant if call is type stable, if not, consider using a condition to filter.\n\njulia> using LightQuery\n\njulia> order([2, 1], identity)\n2-element view(::Array{Int64,1}, [2, 1]) with eltype Int64:\n 1\n 2\n\njulia> order([2, 1, missing], identity, !ismissing)\n2-element view(::Array{Union{Missing, Int64},1}, [2, 1]) with eltype Union{Missing, Int64}:\n 1\n 2\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.By",
    "page": "Tutorial",
    "title": "LightQuery.By",
    "category": "type",
    "text": "By(it, call)\n\nMark that it has been pre-sorted by call. For use with Group or Join.\n\njulia> using LightQuery\n\njulia> By([1, 2], identity)\nBy{Array{Int64,1},typeof(identity)}([1, 2], identity)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Group",
    "page": "Tutorial",
    "title": "LightQuery.Group",
    "category": "type",
    "text": "Group(it::By)\n\nGroup consecutive keys in it. Requires a presorted object (see By). Relies on the fact that iteration states can be converted to indices; thus, you might have to define LightQuery.state_to_index for unrecognized types.\n\njulia> using LightQuery\n\njulia> Group(By([1, 3, 2, 4], iseven)) |> collect\n2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:\n 0 => [1, 3]\n 1 => [2, 4]\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.key",
    "page": "Tutorial",
    "title": "LightQuery.key",
    "category": "function",
    "text": "key(it)\n\nThe key in a key => value pair.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.value",
    "page": "Tutorial",
    "title": "LightQuery.value",
    "category": "function",
    "text": "value(it)\n\nThe value in a key => value pair.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Join",
    "page": "Tutorial",
    "title": "LightQuery.Join",
    "category": "type",
    "text": "Join(left::By, right::By)\n\nFind all pairs where isequal(left.call(left.it), right.call(right.it)).\n\njulia> using LightQuery\n\njulia> Join(\n            By([1, 2, 5, 6], identity),\n            By([1, 3, 4, 6], identity)\n        ) |>\n        collect\n6-element Array{Pair{Union{Missing, Int64},Union{Missing, Int64}},1}:\n       1 => 1\n       2 => missing\n missing => 3\n missing => 4\n       5 => missing\n       6 => 6\n\nAssumes left and right are both strictly sorted (no repeats). If there are repeats, Group first.\n\njulia> @> [1, 1, 2, 2] |>\n        Group(By(_, identity)) |>\n        By(_, first) |>\n        Join(_, By([1, 2], identity)) |>\n        collect\n2-element Array{Pair{Pair{Int64,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},Int64},1}:\n (1 => [1, 1]) => 1\n (2 => [2, 2]) => 2\n\nFor other join flavors, combine with when. Make sure to annotate with  Length if you know it.\n\njulia> @> Join(\n            By([1, 2, 5, 6], identity),\n            By([1, 3, 4, 6], identity)\n        ) |>\n        when(_, @_ !ismissing(_.first)) |>\n        Length(_, 4) |>\n        collect\n4-element Array{Pair{Union{Missing, Int64},Union{Missing, Int64}},1}:\n 1 => 1\n 2 => missing\n 5 => missing\n 6 => 6\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Length",
    "page": "Tutorial",
    "title": "LightQuery.Length",
    "category": "type",
    "text": "Length(it, length)\n\nAllow optimizations based on length. Especially useful after Join and before make_columns.\n\njulia> using LightQuery\n\njulia> @> Filter(iseven, 1:4) |>\n        Length(_, 2) |>\n        collect\n2-element Array{Int64,1}:\n 2\n 4\n\n\n\n\n\n"
},

{
    "location": "#Rows-1",
    "page": "Tutorial",
    "title": "Rows",
    "category": "section",
    "text": "unzip\nover\nwhen\norder\nBy\nGroup\nkey\nvalue\nJoin\nLength"
},

{
    "location": "#LightQuery.item_names",
    "page": "Tutorial",
    "title": "LightQuery.item_names",
    "category": "function",
    "text": "item_names(it)\n\nFind names of items in it. Used in Peek and make_columns.\n\njulia> using LightQuery\n\njulia> [(a = 1, b = 1.0), (a = 2, b = 2.0)] |>\n        item_names\n(:a, :b)\n\nIf inference cannot detect names, it will use propertynames of the first item. Map Names over it to override this behavior.\n\njulia> [(a = 1,), (a = 2, b = 2.0)] |>\n        Peek\n|  :a |\n| ---:|\n|   1 |\n|   2 |\n\njulia> @> [(a = 1,), (a = 2, b = 2.0)] |>\n        over(_, Names(:a, :b)) |>\n        Peek\n|  :a |      :b |\n| ---:| -------:|\n|   1 | missing |\n|   2 |     2.0 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rows",
    "page": "Tutorial",
    "title": "LightQuery.rows",
    "category": "function",
    "text": "rows(it)\n\nIterator over rows of a NamedTuple of arrays. Always lazy. Inverse of columns. See Peek for a way to view.\n\njulia> using LightQuery\n\njulia> (a = [1, 2], b = [1.0, 2.0]) |>\n        rows |>\n        collect\n2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Float64}},1}:\n (a = 1, b = 1.0)\n (a = 2, b = 2.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Peek",
    "page": "Tutorial",
    "title": "LightQuery.Peek",
    "category": "type",
    "text": "Peek(it; max_rows = 4)\n\nGet a peek of an iterator which returns named tuples. Will show no more than max_rows. Relies on item_names.\n\njulia> using LightQuery\n\njulia> (a = 1:5, b = 5:-1:1) |>\n        rows |>\n        Peek\nShowing 4 of 5 rows\n|  :a |  :b |\n| ---:| ---:|\n|   1 |   5 |\n|   2 |   4 |\n|   3 |   3 |\n|   4 |   2 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.columns",
    "page": "Tutorial",
    "title": "LightQuery.columns",
    "category": "function",
    "text": "columns(it)\n\nInverse of rows. Always lazy, see make_columns for eager version.\n\njulia> using LightQuery\n\njulia> (a = [1], b = [1.0]) |>\n        rows |>\n        columns\n(a = [1], b = [1.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.make_columns",
    "page": "Tutorial",
    "title": "LightQuery.make_columns",
    "category": "function",
    "text": "make_columns(it)\n\nCollect into columns. Always eager, see columns for lazy version. Relies on item_names.\n\njulia> using LightQuery\n\njulia> [(a = 1, b = 1.0), (a = 2, b = 2.0)] |>\n        make_columns\n(a = [1, 2], b = [1.0, 2.0])\n\n\n\n\n\n"
},

{
    "location": "#Pivot-1",
    "page": "Tutorial",
    "title": "Pivot",
    "category": "section",
    "text": "item_names\nrows\nPeek\ncolumns\nmake_columns"
},

]}
