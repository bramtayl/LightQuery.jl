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
    "text": "I\'m going to use the flights data from the dplyr tutorial. This data is in the test folder of this package; I created it with the following R code:library(nycflights13)\nsetwd(\"C:/Users/hp/.julia/dev/LightQuery/test\")\nwrite.csv(airports, \"airports.csv\", na = \"\", row.names = FALSE)\nwrite.csv(flights, \"flights.csv\", na = \"\", row.names = FALSE)Let\'s import the tools we need. I\'m pulling in from tools from Dates and TimeZones and modifying them to work with missing data.julia> using LightQuery\n\njulia> using Dates: DateTime, Day, Minute\n\njulia> Minute(::Missing) = missing;\n\njulia> using Unitful: mi, °, ft\n\njulia> using TimeZones: TimeZone, VariableTimeZone, ZonedDateTime\n\njulia> TimeZone_or_missing(time_zone) =\n            try\n                TimeZone(time_zone)\n            catch an_error\n                if isa(an_error, ArgumentError)\n                    missing\n                else\n                    rethrow(an_error)\n                end\n            end;\n\njulia> ZonedDateTime(::DateTime, ::Missing) = missing;I re-export CSV for input-output. See the documentation there for information about CSV.File.julia> airports_file = CSV.File(\"airports.csv\",\n            allowmissing = :auto\n        )\nCSV.File(\"airports.csv\", rows=1458):\nTables.Schema:\n :faa    String\n :name   String\n :lat    Float64\n :lon    Float64\n :alt    Int64\n :tz     Int64\n :dst    String\n :tzone  StringLet\'s take a look at the first row. Use named_tuple to coerce a CSV.Row to a NamedTuple.julia> airport =\n        airports_file |>\n        first |>\n        named_tuple\n(faa = \"04G\", name = \"Lansdowne Airport\", lat = 41.1304722, lon = -80.6195833, alt = 1044, tz = -5, dst = \"A\", tzone = \"America/New_York\")As a start, I want to rename so that I understand what the columns mean. When you rename, names need to be wrapped with Name. Here, I use the chaining macro @> to chain several calls together.julia> airport =\n        @> airport |>\n        rename(_,\n            airport_code = Name(:faa),\n            latitude = Name(:lat),\n            longitude = Name(:lon),\n            altitude = Name(:alt),\n            time_zone_offset = Name(:tz),\n            daylight_savings = Name(:dst),\n            time_zone = Name(:tzone)\n        )\n(name = \"Lansdowne Airport\", airport_code = \"04G\", latitude = 41.1304722, longitude = -80.6195833, altitude = 1044, time_zone_offset = -5, daylight_savings = \"A\", time_zone = \"America/New_York\")Let\'s create a proper TimeZone.julia> airport =\n        @> airport |>\n        transform(_,\n            time_zone = TimeZone_or_missing(_.time_zone)\n        )\n(name = \"Lansdowne Airport\", airport_code = \"04G\", latitude = 41.1304722, longitude = -80.6195833, altitude = 1044, time_zone_offset = -5, daylight_savings = \"A\", time_zone = America/New_York (UTC-5/UTC-4))Now that we have a true timezone, we can remove all data that is contingent on timezone.julia> airport =\n        @> airport |>\n        remove(_,\n            :time_zone_offset,\n            :daylight_savings\n        )\n(name = \"Lansdowne Airport\", airport_code = \"04G\", latitude = 41.1304722, longitude = -80.6195833, altitude = 1044, time_zone = America/New_York (UTC-5/UTC-4))Let\'s also add proper units to our variables.julia> airport =\n        @> airport |>\n        transform(_,\n            latitude = _.latitude * °,\n            longitude = _.longitude * °,\n            altitude = _.altitude * ft\n        )\n(name = \"Lansdowne Airport\", airport_code = \"04G\", latitude = 41.1304722°, longitude = -80.6195833°, altitude = 1044 ft, time_zone = America/New_York (UTC-5/UTC-4))Let\'s put it all together.julia> function process_airport(airport_row)\n            @> airport_row |>\n            named_tuple |>\n            rename(_,\n                airport_code = Name(:faa),\n                latitude = Name(:lat),\n                longitude = Name(:lon),\n                altitude = Name(:alt),\n                time_zone_offset = Name(:tz),\n                daylight_savings = Name(:dst),\n                time_zone = Name(:tzone)\n            ) |>\n            transform(_,\n                time_zone = TimeZone_or_missing(_.time_zone),\n                latitude = _.latitude * °,\n                longitude = _.longitude * °,\n                altitude = _.altitude * ft\n            ) |>\n            remove(_,\n                :time_zone_offset,\n                :daylight_savings\n            )\n        end;I use over to lazily map.julia> airports =\n        @> airports_file |>\n        over(_, process_airport);When it comes time to collect, I\'m calling make_columns then rows. It makes sense to store this data column-wise. This is because there are multiple columns that might contain missing data.julia> airports =\n        airports |>\n        make_columns |>\n        rows;We can use Peek to get a look at the data.julia> Peek(airports)\nShowing 4 of 1458 rows\n|                         :name | :airport_code |   :latitude |   :longitude | :altitude |                     :time_zone |\n| -----------------------------:| -------------:| -----------:| ------------:| ---------:| ------------------------------:|\n|             Lansdowne Airport |           04G | 41.1304722° | -80.6195833° |   1044 ft | America/New_York (UTC-5/UTC-4) |\n| Moton Field Municipal Airport |           06A | 32.4605722° | -85.6800278° |    264 ft |  America/Chicago (UTC-6/UTC-5) |\n|           Schaumburg Regional |           06C | 41.9893408° | -88.1012428° |    801 ft |  America/Chicago (UTC-6/UTC-5) |\n|               Randall Airport |           06N |  41.431912° | -74.3915611° |    523 ft | America/New_York (UTC-5/UTC-4) |I\'ll also make sure the airports are indexed by their code so we can access them quickly.julia> airports =\n        @> airports |>\n        indexed(_, Name(:airport_code));\n\njulia> airports[\"JFK\"]\n(name = \"John F Kennedy Intl\", airport_code = \"JFK\", latitude = 40.639751°, longitude = -73.778925°, altitude = 13 ft, time_zone = America/New_York (UTC-5/UTC-4))That was just the warm-up. Now let\'s get started working on the flights data.julia> flights_file = CSV.File(\"flights.csv\", allowmissing = :auto)\nCSV.File(\"flights.csv\", rows=336776):\nTables.Schema:\n :year            Int64\n :month           Int64\n :day             Int64\n :dep_time        Union{Missing, Int64}\n :sched_dep_time  Int64\n :dep_delay       Union{Missing, Int64}\n :arr_time        Union{Missing, Int64}\n :sched_arr_time  Int64\n :arr_delay       Union{Missing, Int64}\n :carrier         String\n :flight          Int64\n :tailnum         Union{Missing, String}\n :origin          String\n :dest            String\n :air_time        Union{Missing, Int64}\n :distance        Int64\n :hour            Int64\n :minute          Int64\n :time_hour       String\n\njulia> flight =\n        @> flights_file |>\n        first |>\n        named_tuple |>\n        rename(_,\n            departure_time = Name(:dep_time),\n            scheduled_departure_time = Name(:sched_dep_time),\n            departure_delay = Name(:dep_delay),\n            arrival_time = Name(:arr_time),\n            scheduled_arrival_time = Name(:sched_arr_time),\n            arrival_delay = Name(:arr_delay),\n            tail_number = Name(:tailnum),\n            destination = Name(:dest)\n        )\n(year = 2013, month = 1, day = 1, carrier = \"UA\", flight = 1545, origin = \"EWR\", air_time = 227, distance = 1400, hour = 5, minute = 15, time_hour = \"2013-01-01 05:00:00\", departure_time = 517, scheduled_departure_time = 515, departure_delay = 2, arrival_time = 830, scheduled_arrival_time = 819, arrival_delay = 11, tail_number = \"N14228\", destination = \"IAH\")We can use our airports data to make datetimes with timezones.julia> scheduled_departure_time = ZonedDateTime(\n            DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),\n            airports[flight.origin].time_zone\n        )\n2013-01-01T05:15:00-05:00Note the scheduled arrival time is 818. This means 8:18. We can use divrem(_, 100) to split it up. Note I\'m accessing the time_zone with Name (which will default to missing). This is because some of the destinations are not in the flights dataset.julia> scheduled_arrival_time = ZonedDateTime(\n            DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),\n            Name(:time_zone)(airports[flight.destination]))\n2013-01-01T08:19:00-06:00What if it was an overnight flight? We can add a day to the arrival time if it wasn\'t later than the departure time.julia> if scheduled_arrival_time !== missing && !(scheduled_arrival_time > scheduled_departure_time)\n            scheduled_arrival_time = scheduled_arrival_time + Day(1)\n        endLet\'s put it all together:julia> function process_flight(row)\n            flight =\n                @> named_tuple(row) |>\n                rename(_,\n                    departure_time = Name(:dep_time),\n                    scheduled_departure_time = Name(:sched_dep_time),\n                    departure_delay = Name(:dep_delay),\n                    arrival_time = Name(:arr_time),\n                    scheduled_arrival_time = Name(:sched_arr_time),\n                    arrival_delay = Name(:arr_delay),\n                    tail_number = Name(:tailnum),\n                    destination = Name(:dest)\n                )\n            scheduled_departure_time = ZonedDateTime(\n                DateTime(flight.year, flight.month, flight.day, flight.hour, flight.minute),\n                airports[flight.origin].time_zone\n            )\n            scheduled_arrival_time = ZonedDateTime(\n                DateTime(flight.year, flight.month, flight.day, divrem(flight.scheduled_arrival_time, 100)...),\n                Name(:time_zone)(airports[flight.destination])\n            )\n            if scheduled_arrival_time !== missing && !(scheduled_arrival_time > scheduled_departure_time)\n                scheduled_arrival_time = scheduled_arrival_time + Day(1)\n            end\n            @> flight |>\n                transform(_,\n                    scheduled_departure_time = scheduled_departure_time,\n                    scheduled_arrival_time = scheduled_arrival_time,\n                    air_time = Minute(_.air_time),\n                    distance = _.distance * mi,\n                    departure_delay = Minute(_.departure_delay),\n                    arrival_delay = Minute(_.arrival_delay)\n                ) |>\n                remove(_, :year, :month, :day, :hour, :minute, :time_hour,\n                    :departure_time, :arrival_time)\n        end;\n\njulia> flights =\n        @> flights_file |>\n        over(_, process_flight) |>\n        make_columns |>\n        rows;\n\njulia> Peek(flights)\nShowing 4 of 336776 rows\n| :carrier | :flight | :origin |   :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |\n| --------:| -------:| -------:| -----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|\n|       UA |    1545 |     EWR | 227 minutes |   1400 mi | 2013-01-01T05:15:00-05:00 |        2 minutes | 2013-01-01T08:19:00-06:00 |     11 minutes |       N14228 |          IAH |\n|       UA |    1714 |     LGA | 227 minutes |   1416 mi | 2013-01-01T05:29:00-05:00 |        4 minutes | 2013-01-01T08:30:00-06:00 |     20 minutes |       N24211 |          IAH |\n|       AA |    1141 |     JFK | 160 minutes |   1089 mi | 2013-01-01T05:40:00-05:00 |        2 minutes | 2013-01-01T08:50:00-05:00 |     33 minutes |       N619AA |          MIA |\n|       B6 |     725 |     JFK | 183 minutes |   1576 mi | 2013-01-01T05:45:00-05:00 |        -1 minute |                   missing |    -18 minutes |       N804JB |          BQN |Theoretically, the distances between two airports is always the same. Let\'s make sure this is also the case in our data. First, order by origin, destination, and distance. Then Group By the same variables.julia> paths_grouped =\n        @> flights |>\n        order(_, Names(:origin, :destination, :distance)) |>\n        Group(By(_, Names(:origin, :destination, :distance)));Each Group will contain a key and valuejulia> path = first(paths_grouped);\n\njulia> key(path)\n(origin = \"EWR\", destination = \"ALB\", distance = 143 mi)\n\njulia> value(path) |> Peek\nShowing 4 of 439 rows\n| :carrier | :flight | :origin |  :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |\n| --------:| -------:| -------:| ----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|\n|       EV |    4112 |     EWR | 33 minutes |    143 mi | 2013-01-01T13:17:00-05:00 |       -2 minutes | 2013-01-01T14:23:00-05:00 |    -10 minutes |       N13538 |          ALB |\n|       EV |    3260 |     EWR | 36 minutes |    143 mi | 2013-01-01T16:21:00-05:00 |       34 minutes | 2013-01-01T17:24:00-05:00 |     40 minutes |       N19554 |          ALB |\n|       EV |    4170 |     EWR | 31 minutes |    143 mi | 2013-01-01T20:04:00-05:00 |       52 minutes | 2013-01-01T21:12:00-05:00 |     44 minutes |       N12540 |          ALB |\n|       EV |    4316 |     EWR | 33 minutes |    143 mi | 2013-01-02T13:27:00-05:00 |        5 minutes | 2013-01-02T14:33:00-05:00 |    -14 minutes |       N14153 |          ALB |At this point, we don\'t need any of the value data. All we need is the key.julia> paths =\n        @> paths_grouped |>\n        over(_, key) |>\n        make_columns |>\n        rows;\n\njulia> Peek(paths)\nShowing 4 of 226 rows\n| :origin | :destination | :distance |\n| -------:| ------------:| ---------:|\n|     EWR |          ALB |    143 mi |\n|     EWR |          ANC |   3370 mi |\n|     EWR |          ATL |    746 mi |\n|     EWR |          AUS |   1504 mi |Notice the data is already sorted by origin and destination, so that for our second Group, we don\'t need to order first.julia> distinct_distances =\n        @> paths |>\n        Group(By(_, Names(:origin, :destination))) |>\n        over(_, @_ transform(key(_),\n            number = length(value(_))\n        ));\n\njulia> Peek(distinct_distances)\nShowing at most 4 rows\n| :origin | :destination | :number |\n| -------:| ------------:| -------:|\n|     EWR |          ALB |       1 |\n|     EWR |          ANC |       1 |\n|     EWR |          ATL |       1 |\n|     EWR |          AUS |       1 |Let\'s see when there are multiple distances for the same path:julia> @> distinct_distances |>\n        when(_, @_ _.number != 1) |>\n        Peek\nShowing at most 4 rows\n| :origin | :destination | :number |\n| -------:| ------------:| -------:|\n|     EWR |          EGE |       2 |\n|     JFK |          EGE |       2 |That\'s strange. What\'s up with the EGE airport? Let\'s take a Peek.julia> @> flights |>\n        when(_, @_ _.destination == \"EGE\") |>\n        Peek\nShowing at most 4 rows\n| :carrier | :flight | :origin |   :air_time | :distance | :scheduled_departure_time | :departure_delay |   :scheduled_arrival_time | :arrival_delay | :tail_number | :destination |\n| --------:| -------:| -------:| -----------:| ---------:| -------------------------:| ----------------:| -------------------------:| --------------:| ------------:| ------------:|\n|       UA |    1597 |     EWR | 287 minutes |   1726 mi | 2013-01-01T09:28:00-05:00 |       -2 minutes | 2013-01-01T12:20:00-07:00 |     13 minutes |       N27733 |          EGE |\n|       AA |     575 |     JFK | 280 minutes |   1747 mi | 2013-01-01T17:00:00-05:00 |       -5 minutes | 2013-01-01T19:50:00-07:00 |      3 minutes |       N5DRAA |          EGE |\n|       UA |    1597 |     EWR | 261 minutes |   1726 mi | 2013-01-02T09:28:00-05:00 |         1 minute | 2013-01-02T12:20:00-07:00 |      3 minutes |       N24702 |          EGE |\n|       AA |     575 |     JFK | 260 minutes |   1747 mi | 2013-01-02T17:00:00-05:00 |        5 minutes | 2013-01-02T19:50:00-07:00 |     16 minutes |       N631AA |          EGE |Looks (to me) like two different sources are reporting different info about the same flight."
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
    "text": "named_tuple(it)\n\nCoerce to a named_tuple. For performance with working with arbitrary structs, define and @inline propertynames.\n\njulia> using LightQuery\n\njulia> @inline Base.propertynames(p::Pair) = (:first, :second);\n\njulia> named_tuple(:a => 1)\n(first = :a, second = 1)\n\n\n\n\n\n"
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
    "location": "#LightQuery.Enumerated",
    "page": "Tutorial",
    "title": "LightQuery.Enumerated",
    "category": "type",
    "text": "Enumerated{It}\n\nRelies on the fact that iteration states can be converted to indices; thus, you might have to define LightQuery.state_to_index for unrecognized types. Ignores some iterators like Filter.\n\njulia> using LightQuery\n\njulia> when([4, 3, 2, 1], iseven) |> Enumerated |> collect\n2-element Array{Tuple{Int64,Int64},1}:\n (1, 4)\n (3, 2)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.over",
    "page": "Tutorial",
    "title": "LightQuery.over",
    "category": "function",
    "text": "over(it, call)\n\nLazy map with argument order reversed.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.indexed",
    "page": "Tutorial",
    "title": "LightQuery.indexed",
    "category": "function",
    "text": "indexed(it, call)\n\nIndex it by the results of call, with a default to missing. Relies on Enumerated.\n\n```jldoctest julia> using LightQuery\n\njulia> result = indexed(             [                 (item = \"b\", index = 2),                 (item = \"a\", index = 1)             ],             Name(:index)         );\n\njulia> result1\n\njulia> result[3] missing\n\n\n\n\n\n"
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
    "text": "order(it, call; keywords...)\n\nGeneralized sort. keywords will be passed to sort!; see the documentation there for options. See By for a way to explicitly mark that an object has been sorted. Relies on Enumerated.\n\njulia> using LightQuery\n\njulia> order([\n            (item = \"b\", index = 2),\n            (item = \"a\", index = 1)\n        ], Names(:index))\n2-element view(::Array{NamedTuple{(:item, :index),Tuple{String,Int64}},1}, [2, 1]) with eltype NamedTuple{(:item, :index),Tuple{String,Int64}}:\n (item = \"a\", index = 1)\n (item = \"b\", index = 2)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.By",
    "page": "Tutorial",
    "title": "LightQuery.By",
    "category": "type",
    "text": "By(it, call)\n\nMark that it has been pre-sorted by call. For use with Group or Join.\n\njulia> using LightQuery\n\njulia> By([\n            (item = \"a\", index = 1),\n            (item = \"b\", index = 2)\n        ], Names(:index));\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Group",
    "page": "Tutorial",
    "title": "LightQuery.Group",
    "category": "type",
    "text": "Group(it::By)\n\nGroup consecutive keys in it. Requires a presorted object (see By). Relies on Enumerated.\n\njulia> using LightQuery\n\njulia> Group(By(\n            [\n                (item = \"a\", group = 1),\n                (item = \"b\", group = 1),\n                (item = \"c\", group = 2),\n                (item = \"d\", group = 2)\n            ],\n            Names(:group)\n        )) |>\n        collect\n2-element Array{Pair{NamedTuple{(:group,),Tuple{Int64}},SubArray{NamedTuple{(:item, :group),Tuple{String,Int64}},1,Array{NamedTuple{(:item, :group),Tuple{String,Int64}},1},Tuple{UnitRange{Int64}},true}},1}:\n (group = 1,) => [(item = \"a\", group = 1), (item = \"b\", group = 1)]\n (group = 2,) => [(item = \"c\", group = 2), (item = \"d\", group = 2)]\n\n\n\n\n\n"
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
    "text": "Join(left::By, right::By)\n\nFind all pairs where isequal(left.call(left.it), right.call(right.it)).\n\njulia> using LightQuery\n\njulia> Join(\n            By(\n                [\n                    (left = \"a\", index = 1),\n                    (left = \"b\", index = 2),\n                    (left = \"e\", index = 5),\n                    (left = \"f\", index = 6)\n                ],\n                Names(:index)\n            ),\n            By(\n                [\n                    (right = \"a\", index = 1),\n                    (right = \"c\", index = 3),\n                    (right = \"d\", index = 4),\n                    (right = \"e\", index = 6)\n                ],\n                Names(:index)\n            )\n        ) |>\n        collect\n6-element Array{Pair{Union{Missing, NamedTuple{(:left, :index),Tuple{String,Int64}}},Union{Missing, NamedTuple{(:right, :index),Tuple{String,Int64}}}},1}:\n (left = \"a\", index = 1) => (right = \"a\", index = 1)\n (left = \"b\", index = 2) => missing\n                 missing => (right = \"c\", index = 3)\n                 missing => (right = \"d\", index = 4)\n (left = \"e\", index = 5) => missing\n (left = \"f\", index = 6) => (right = \"e\", index = 6)\n\nAssumes left and right are both strictly sorted (no repeats). If there are repeats, Group first. For other join flavors, combine with when. Make sure to annotate with Length if you know it.\n\n\n\n\n\n"
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
    "text": "unzip\nEnumerated\nover\nindexed\nwhen\norder\nBy\nGroup\nkey\nvalue\nJoin\nLength"
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
    "text": "Peek(it; max_rows = 4)\n\nGet a peek of an iterator which returns items with propertynames. Will show no more than max_rows. Relies on item_names.\n\njulia> using LightQuery\n\njulia> (a = 1:5, b = 5:-1:1) |>\n        rows |>\n        Peek\nShowing 4 of 5 rows\n|  :a |  :b |\n| ---:| ---:|\n|   1 |   5 |\n|   2 |   4 |\n|   3 |   3 |\n|   4 |   2 |\n\n\n\n\n\n"
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
