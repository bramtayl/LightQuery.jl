var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "LightQuery.jl",
    "title": "LightQuery.jl",
    "category": "page",
    "text": ""
},

{
    "location": "#LightQuery.jl-1",
    "page": "LightQuery.jl",
    "title": "LightQuery.jl",
    "category": "section",
    "text": ""
},

{
    "location": "#Introduction-to-LightQuery-1",
    "page": "LightQuery.jl",
    "title": "Introduction to LightQuery",
    "category": "section",
    "text": "Follows the tutorial here. I\'ll make heavy use of the chaining macro @> and lazy calling macro @_ included in this package. The syntax here is in most cases more verbose but also more flexible than dplyr. Fortunately, programming with LightQuery is much easier, so define shortcuts."
},

{
    "location": "#Data-1",
    "page": "LightQuery.jl",
    "title": "Data",
    "category": "section",
    "text": "Use Peek to view iterators of NamedTuples. The data is stored column-wise; rows is a lazy view.julia> using LightQuery\n\njulia> flights =\n        @> \"flights.csv\" |>\n        CSV.read(_, allowmissing = :auto) |>\n        named_tuple |>\n        rows;\n\njulia> Peek(flights)\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |"
},

{
    "location": "#Single-table-verbs-1",
    "page": "LightQuery.jl",
    "title": "Single table verbs",
    "category": "section",
    "text": ""
},

{
    "location": "#Filter-rows-1",
    "page": "LightQuery.jl",
    "title": "Filter rows",
    "category": "section",
    "text": "julia> @> flights |>\n        when(_, @_ _.month == 1 && _.day == 1) |>\n        Peek\nShowing at most 4 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |In some cases, a column-wise filter might be more efficient.julia> @> flights |>\n        columns |>\n        (_.month .== 1 .& _.day .== 1) |>\n        view(flights, _) |>\n        Peek\nShowing 4 of 13936 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |"
},

{
    "location": "#Order-rows-1",
    "page": "LightQuery.jl",
    "title": "Order rows",
    "category": "section",
    "text": "julia> @> flights |>\n        order(_, Names(:year, :month, :day)) |>\n        Peek\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |For performance, filter out instabilities.julia> @> flights |>\n        order(_, Names(:arr_delay), (@_ !ismissing(_.arr_delay)), rev = true) |>\n        Peek\nShowing 4 of 327346 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|\n|  2013 |      1 |    9 |       641 |             900 |       1301 |      1242 |            1530 |       1272 |       HA |      51 |   N384HA |     JFK |   HNL |       640 |      4983 |     9 |       0 | 2013-01-09 09:00:00 |\n|  2013 |      6 |   15 |      1432 |            1935 |       1137 |      1607 |            2120 |       1127 |       MQ |    3535 |   N504MQ |     JFK |   CMH |        74 |       483 |    19 |      35 | 2013-06-15 19:00:00 |\n|  2013 |      1 |   10 |      1121 |            1635 |       1126 |      1239 |            1810 |       1109 |       MQ |    3695 |   N517MQ |     EWR |   ORD |       111 |       719 |    16 |      35 | 2013-01-10 16:00:00 |\n|  2013 |      9 |   20 |      1139 |            1845 |       1014 |      1457 |            2210 |       1007 |       AA |     177 |   N338AA |     JFK |   SFO |       354 |      2586 |    18 |      45 | 2013-09-20 18:00:00 |"
},

{
    "location": "#Select-columns-1",
    "page": "LightQuery.jl",
    "title": "Select columns",
    "category": "section",
    "text": "Lazily convert to columns then back to rows for columnwise operations.julia> @> flights |>\n        columns |>\n        Names(:year, :month, :day)(_) |>\n        rows |>\n        Peek\nShowing 4 of 336776 rows\n| :year | :month | :day |\n| -----:| ------:| ----:|\n|  2013 |      1 |    1 |\n|  2013 |      1 |    1 |\n|  2013 |      1 |    1 |\n|  2013 |      1 |    1 |julia> @> flights |>\n        columns |>\n        remove(_, :year, :month, :day) |>\n        rows |>\n        Peek\nShowing 4 of 336776 rows\n| :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour |\n| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:|\n|       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |\n|       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |\n|       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |\n|       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |julia> @> flights |>\n        columns |>\n        rename(_, tail_num = Name(:tailnum)) |>\n        rows |>\n        Peek\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour | :tail_num |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:| ---------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |    N14228 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |    N24211 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |    N619AA |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |    N804JB |"
},

{
    "location": "#Add-new-columns-1",
    "page": "LightQuery.jl",
    "title": "Add new columns",
    "category": "section",
    "text": "julia> @> flights |>\n        columns |>\n        transform(_,\n            gain = _.arr_delay .- _.dep_delay,\n            speed = _.distance ./ _.air_time * 60\n        ) |>\n        rows |>\n        Peek\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier | :flight | :tailnum | :origin | :dest | :air_time | :distance | :hour | :minute |          :time_hour | :gain |             :speed |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:| -------:| --------:| -------:| -----:| ---------:| ---------:| -----:| -------:| -------------------:| -----:| ------------------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |             819 |         11 |       UA |    1545 |   N14228 |     EWR |   IAH |       227 |      1400 |     5 |      15 | 2013-01-01 05:00:00 |     9 | 370.04405286343615 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |             830 |         20 |       UA |    1714 |   N24211 |     LGA |   IAH |       227 |      1416 |     5 |      29 | 2013-01-01 05:00:00 |    16 |  374.2731277533039 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |             850 |         33 |       AA |    1141 |   N619AA |     JFK |   MIA |       160 |      1089 |     5 |      40 | 2013-01-01 05:00:00 |    31 |            408.375 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |     725 |   N804JB |     JFK |   BQN |       183 |      1576 |     5 |      45 | 2013-01-01 05:00:00 |   -17 |  516.7213114754098 |"
},

{
    "location": "#Grouped-operations-1",
    "page": "LightQuery.jl",
    "title": "Grouped operations",
    "category": "section",
    "text": "You can only group sorted data. Each group is a pair, from key to value (sub-table).julia> using Statistics: mean\n\njulia> @> flights |>\n        order(_, Names(:tailnum), (@_ !ismissing(_.tailnum))) |>\n        Group(By(_, Names(:tailnum))) |>\n        over(_, @_ transform(key(_),\n            count = length(value(_)),\n            dist = (@> columns(value(_)).distance |> skipmissing |> mean),\n            delay = (@> columns(value(_)).arr_delay |> skipmissing |> mean)\n        )) |>\n        Peek\nShowing at most 4 rows\n| :tailnum | :count |             :dist |             :delay |\n| --------:| ------:| -----------------:| ------------------:|\n|   D942DN |      4 |             854.5 |               31.5 |\n|   N0EGMQ |    371 |  676.188679245283 |  9.982954545454545 |\n|   N10156 |    153 | 757.9477124183006 | 12.717241379310344 |\n|   N102UW |     48 |           535.875 |             2.9375 |"
},

{
    "location": "#Two-table-verbs-1",
    "page": "LightQuery.jl",
    "title": "Two table verbs",
    "category": "section",
    "text": "Follows the tutorial here.You can only Join presorted data. A join will return pairs from an item on the left (first) to an item on the right (second). Group data with repeats. flatten is reexported from Base.julia> flights2 =\n        @> flights |>\n        columns |>\n        Names(:year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier)(_) |>\n        rows;\n\njulia> airlines =\n        @> \"airlines.csv\" |>\n        CSV.read(_, allowmissing = :auto,) |>\n        named_tuple |>\n        rows;\n\njulia> Peek(airlines)\nShowing 4 of 16 rows\n| :carrier |                  :name |\n| --------:| ----------------------:|\n|       9E |      Endeavor Air Inc. |\n|       AA | American Airlines Inc. |\n|       AS |   Alaska Airlines Inc. |\n|       B6 |        JetBlue Airways |\n\njulia> @> flights2 |>\n        order(_, Names(:carrier)) |>\n        Group(By(_, Names(:carrier))) |>\n        By(_, key) |>\n        Join(_, By(airlines, Names(:carrier))) |>\n        over(_, pair -> over(value(pair.first), @_ merge(_, pair.second))) |>\n        flatten |>\n        Peek\nShowing at most 4 rows\n| :year | :month | :day | :hour | :origin | :dest | :tailnum | :carrier |             :name |\n| -----:| ------:| ----:| -----:| -------:| -----:| --------:| --------:| -----------------:|\n|  2013 |      1 |    1 |     8 |     JFK |   MSP |   N915XJ |       9E | Endeavor Air Inc. |\n|  2013 |      1 |    1 |    15 |     JFK |   IAD |   N8444F |       9E | Endeavor Air Inc. |\n|  2013 |      1 |    1 |    14 |     JFK |   BUF |   N920XJ |       9E | Endeavor Air Inc. |\n|  2013 |      1 |    1 |    15 |     JFK |   SYR |   N8409N |       9E | Endeavor Air Inc. |Join is full by default; use when to mimic other kinds of joins.julia> weather =\n        @> \"weather.csv\" |>\n        CSV.read(_, allowmissing = :auto) |>\n        named_tuple |>\n        rows;\n\njulia> Peek(weather)\nShowing 4 of 26115 rows\n| :origin | :year | :month | :day | :hour | :temp | :dewp | :humid | :wind_dir | :wind_speed | :wind_gust | :precip | :pressure | :visib |          :time_hour |\n| -------:| -----:| ------:| ----:| -----:| -----:| -----:| ------:| ---------:| -----------:| ----------:| -------:| ---------:| ------:| -------------------:|\n|     EWR |  2013 |      1 |    1 |     1 | 39.02 | 26.06 |  59.37 |       270 |    10.35702 |    missing |     0.0 |    1012.0 |   10.0 | 2013-01-01 01:00:00 |\n|     EWR |  2013 |      1 |    1 |     2 | 39.02 | 26.96 |  61.63 |       250 |     8.05546 |    missing |     0.0 |    1012.3 |   10.0 | 2013-01-01 02:00:00 |\n|     EWR |  2013 |      1 |    1 |     3 | 39.02 | 28.04 |  64.43 |       240 |     11.5078 |    missing |     0.0 |    1012.5 |   10.0 | 2013-01-01 03:00:00 |\n|     EWR |  2013 |      1 |    1 |     4 | 39.92 | 28.04 |  62.21 |       250 |    12.65858 |    missing |     0.0 |    1012.2 |   10.0 | 2013-01-01 04:00:00 |\n\njulia> const selector = Names(:origin, :year, :month, :day, :hour);\n\njulia> @> flights2 |>\n        order(_, selector) |>\n        Group(By(_, selector)) |>\n        By(_, key) |>\n        Join(_, By(weather, selector)) |>\n        when(_, @_ !ismissing(_.first)) |>\n        over(_, pair -> over(value(pair.first), @_ merge(_, pair.second))) |>\n        flatten |>\n        Peek\nShowing at most 4 rows\n| :year | :month | :day | :hour | :origin | :dest | :tailnum | :carrier | :temp | :dewp | :humid | :wind_dir | :wind_speed | :wind_gust | :precip | :pressure | :visib |          :time_hour |\n| -----:| ------:| ----:| -----:| -------:| -----:| --------:| --------:| -----:| -----:| ------:| ---------:| -----------:| ----------:| -------:| ---------:| ------:| -------------------:|\n|  2013 |      1 |    1 |     5 |     EWR |   IAH |   N14228 |       UA | 39.02 | 28.04 |  64.43 |       260 |    12.65858 |    missing |     0.0 |    1011.9 |   10.0 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |     5 |     EWR |   ORD |   N39463 |       UA | 39.02 | 28.04 |  64.43 |       260 |    12.65858 |    missing |     0.0 |    1011.9 |   10.0 | 2013-01-01 05:00:00 |\n|  2013 |      1 |    1 |     6 |     EWR |   FLL |   N516JB |       B6 | 37.94 | 28.04 |  67.21 |       240 |     11.5078 |    missing |     0.0 |    1012.4 |   10.0 | 2013-01-01 06:00:00 |\n|  2013 |      1 |    1 |     6 |     EWR |   SFO |   N53441 |       UA | 37.94 | 28.04 |  67.21 |       240 |     11.5078 |    missing |     0.0 |    1012.4 |   10.0 | 2013-01-01 06:00:00 |\n\njulia> planes =\n        @> \"planes.csv\" |>\n        CSV.read(_, allowmissing = :auto) |>\n        named_tuple |>\n        rename(_, model_year = Name(:year)) |>\n        rows;\n\njulia> Peek(planes)\nShowing 4 of 3322 rows\n| :tailnum |                   :type |    :manufacturer |    :model | :engines | :seats |  :speed |   :engine | :model_year |\n| --------:| -----------------------:| ----------------:| ---------:| --------:| ------:| -------:| ---------:| -----------:|\n|   N10156 | Fixed wing multi engine |          EMBRAER | EMB-145XR |        2 |     55 | missing | Turbo-fan |        2004 |\n|   N102UW | Fixed wing multi engine | AIRBUS INDUSTRIE |  A320-214 |        2 |    182 | missing | Turbo-fan |        1998 |\n|   N103US | Fixed wing multi engine | AIRBUS INDUSTRIE |  A320-214 |        2 |    182 | missing | Turbo-fan |        1999 |\n|   N104UW | Fixed wing multi engine | AIRBUS INDUSTRIE |  A320-214 |        2 |    182 | missing | Turbo-fan |        1999 |\n\njulia> @> flights2 |>\n            order(_, Names(:tailnum), (@_ !ismissing(_.tailnum))) |>\n            Group(By(_, Names(:tailnum))) |>\n            By(_, key) |>\n            Join(_, By(planes, Names(:tailnum))) |>\n            when(_, @_ ismissing(_.second)) |>\n            over(_, @_ transform(key(_.first),\n                n = length(value(_.first))\n            )) |>\n            make_columns |>\n            rows |>\n            order(_, Names(:n), rev = true) |>\n            Peek\nShowing 4 of 721 rows\n| :tailnum |  :n |\n| --------:| ---:|\n|   N725MQ | 575 |\n|   N722MQ | 513 |\n|   N723MQ | 507 |\n|   N713MQ | 483 |"
},

{
    "location": "#Window-functions-1",
    "page": "LightQuery.jl",
    "title": "Window functions",
    "category": "section",
    "text": "Follows the tutorial here.julia> batting =\n        @> \"batting.csv\" |>\n        CSV.read(_, allowmissing = :auto) |>\n        named_tuple |>\n        rows;\n\njulia> Peek(batting)\nShowing 4 of 19404 rows\n| :playerID | :yearID | :teamID |  :G | :AB |  :R |  :H |\n| ---------:| -------:| -------:| ---:| ---:| ---:| ---:|\n| aaronha01 |    1954 |     ML1 | 122 | 468 |  58 | 131 |\n| aaronha01 |    1955 |     ML1 | 153 | 602 | 105 | 189 |\n| aaronha01 |    1956 |     ML1 | 153 | 609 | 106 | 200 |\n| aaronha01 |    1957 |     ML1 | 151 | 615 | 118 | 198 |\n\njulia> players =\n        @> batting |>\n        Group(By(_, Names(:playerID)));\n\njulia> @> players |>\n        over(_, @_ @> order(value(_), Names(:H)) |> view(_, 1:2)) |>\n        flatten |>\n        when(_, @_ _.H > 0) |>\n        Peek\nShowing at most 4 rows\n| :playerID | :yearID | :teamID |  :G | :AB |  :R |  :H |\n| ---------:| -------:| -------:| ---:| ---:| ---:| ---:|\n| aaronha01 |    1976 |     ML4 |  85 | 271 |  22 |  62 |\n| aaronha01 |    1974 |     ATL | 112 | 340 |  47 |  91 |\n| abreubo01 |    1996 |     HOU |  15 |  22 |   1 |   5 |\n| abreubo01 |    2012 |     LAA |   8 |  24 |   1 |   5 |\n\njulia> using StatsBase: ordinalrank\n\njulia> @> players |>\n        over(_, @_ @> columns(value(_)) |>\n            transform(_, G_rank = ordinalrank(_.G)) |>\n            rows\n        ) |>\n        flatten |>\n        Peek\nShowing at most 4 rows\n| :playerID | :yearID | :teamID |  :G | :AB |  :R |  :H | :G_rank |\n| ---------:| -------:| -------:| ---:| ---:| ---:| ---:| -------:|\n| aaronha01 |    1954 |     ML1 | 122 | 468 |  58 | 131 |       4 |\n| aaronha01 |    1955 |     ML1 | 153 | 602 | 105 | 189 |      13 |\n| aaronha01 |    1956 |     ML1 | 153 | 609 | 106 | 200 |      14 |\n| aaronha01 |    1957 |     ML1 | 151 | 615 | 118 | 198 |      12 |"
},

{
    "location": "#Programming-with-LightQuery-1",
    "page": "LightQuery.jl",
    "title": "Programming with LightQuery",
    "category": "section",
    "text": "Follows the tutorial here.Be sure to @inline if you rely on constant propagation.julia> df = (\n            g1 = [1, 1, 2, 2, 2],\n            g2 = [1, 2, 1, 2, 1],\n            a = 1:5,\n            b = 1:5\n        ) |>\n        rows;\n\njulia> Peek(df)\nShowing 4 of 5 rows\n| :g1 | :g2 |  :a |  :b |\n| ---:| ---:| ---:| ---:|\n|   1 |   1 |   1 |   1 |\n|   1 |   2 |   2 |   2 |\n|   2 |   1 |   3 |   3 |\n|   2 |   2 |   4 |   4 |\n\njulia> my_summarize_(df, group_var) =\n        @> df |>\n        order(_, group_var) |>\n        Group(By(_, group_var)) |>\n        over(_, @_ transform(key(_),\n            a = sum(columns(value(_)).a)\n        )) |>\n        make_columns |>\n        rows;\n\njulia> Peek(my_summarize_(df, Names(:g1)))\n| :g1 |  :a |\n| ---:| ---:|\n|   1 |   3 |\n|   2 |  12 |\n\njulia> Peek(my_summarize_(df, Names(:g2)))\n| :g2 |  :a |\n| ---:| ---:|\n|   1 |   9 |\n|   2 |   6 |\n\njulia> @inline my_summarize(df, group_vars...) =\n        my_summarize_(df, Names(group_vars...));\n\njulia> Peek(my_summarize(df, :g1))\n| :g1 |  :a |\n| ---:| ---:|\n|   1 |   3 |\n|   2 |  12 |"
},

{
    "location": "#Index-1",
    "page": "LightQuery.jl",
    "title": "Index",
    "category": "section",
    "text": ""
},

{
    "location": "#LightQuery.By",
    "page": "LightQuery.jl",
    "title": "LightQuery.By",
    "category": "type",
    "text": "By(it, call)\n\nMark that it has been pre-sorted by call. For use with Group or Join.\n\njulia> using LightQuery\n\njulia> By([1, 2], identity)\nBy{Array{Int64,1},typeof(identity)}([1, 2], identity)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Group-Tuple{LightQuery.By}",
    "page": "LightQuery.jl",
    "title": "LightQuery.Group",
    "category": "method",
    "text": "Group(it::By)\n\nGroup consecutive keys in it. Requires a presorted object (see By). Relies on the fact that iteration states can be converted to indices; thus, you might have to define LightQuery.state_to_index for unrecognized types.\n\njulia> using LightQuery\n\njulia> Group(By([1, 3, 2, 4], iseven)) |> collect\n2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:\n 0 => [1, 3]\n 1 => [2, 4]\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Join",
    "page": "LightQuery.jl",
    "title": "LightQuery.Join",
    "category": "type",
    "text": "Join(left::By, right::By)\n\nFind all pairs where isequal(left.call(left.it), right.call(right.it)).\n\njulia> using LightQuery\n\njulia> Join(\n            By([1, 2, 5, 6], identity),\n            By([1, 3, 4, 6], identity)\n        ) |>\n        collect\n6-element Array{Pair{Union{Missing, Int64},Union{Missing, Int64}},1}:\n       1 => 1\n       2 => missing\n missing => 3\n missing => 4\n       5 => missing\n       6 => 6\n\nAssumes left and right are both strictly sorted (no repeats). If there are repeats, Group first.\n\njulia> @> [1, 1, 2, 2] |>\n        Group(By(_, identity)) |>\n        By(_, first) |>\n        Join(_, By([1, 2], identity)) |>\n        collect\n2-element Array{Pair{Pair{Int64,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},Int64},1}:\n (1=>[1, 1]) => 1\n (2=>[2, 2]) => 2\n\nFor other join flavors, combine with when.\n\njulia> @> Join(\n            By([1, 2, 5, 6], identity),\n            By([1, 3, 4, 6], identity)\n        ) |>\n        when(_, @_ !ismissing(_.first)) |>\n        collect\n4-element Array{Pair{Union{Missing, Int64},Union{Missing, Int64}},1}:\n 1 => 1\n 2 => missing\n 5 => missing\n 6 => 6\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Length",
    "page": "LightQuery.jl",
    "title": "LightQuery.Length",
    "category": "type",
    "text": "Length(it, length)\n\nAllow optimizations based on length. Especially useful before make_columns.\n\njulia> using LightQuery\n\njulia> @> Filter(iseven, 1:4) |>\n        Length(_, 2) |>\n        collect\n2-element Array{Int64,1}:\n 2\n 4\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Name-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.Name",
    "category": "method",
    "text": "Name(name)\n\nCreate a typed name. Can be used as a function to getproperty, with a default to missing. For multiple names, see Names.\n\njulia> using LightQuery\n\njulia> (a = 1,) |>\n        Name(:a)\n1\n\njulia> (a = 1,) |>\n        Name(:b)\nmissing\n\njulia> missing |>\n        Name(:a)\nmissing\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Names-Tuple",
    "page": "LightQuery.jl",
    "title": "LightQuery.Names",
    "category": "method",
    "text": "Names(the_names...)\n\nCreate typed names. Can be used to as a function to assign or select names, with a default to missing. For just one name, see Name.\n\njulia> using LightQuery\n\njulia> (1, 1.0) |>\n        Names(:a, :b)\n(a = 1, b = 1.0)\n\njulia> (a = 1, b = 1.0) |>\n        Names(:a)\n(a = 1,)\n\njulia> (a = 1,) |>\n        Names(:a, :b)\n(a = 1, b = missing)\n\njulia> missing |>\n        Names(:a)\n(a = missing,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Peek-Union{Tuple{It}, Tuple{It}} where It",
    "page": "LightQuery.jl",
    "title": "LightQuery.Peek",
    "category": "method",
    "text": "Peek(it; max_rows = 4)\n\nGet a peek of an iterator which returns named tuples. Will show no more than max_rows.\n\njulia> using LightQuery\n\njulia> (a = 1:5, b = 5:-1:1) |>\n        rows |>\n        Peek\nShowing 4 of 5 rows\n|  :a |  :b |\n| ---:| ---:|\n|   1 |   5 |\n|   2 |   4 |\n|   3 |   3 |\n|   4 |   2 |\n\nIf inference cannot detect names, it will use the names of the first item. Map Names over it to override this behavior.\n\njulia> [(a = 1,), (a = 2, b = 2.0)] |>\n        Peek\n|  :a |\n| ---:|\n|   1 |\n|   2 |\n\njulia> @> [(a = 1,), (a = 2, b = 2.0)] |>\n        over(_, Names(:a, :b)) |>\n        Peek\n|  :a |      :b |\n| ---:| -------:|\n|   1 | missing |\n|   2 |     2.0 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.columns-Union{Tuple{Base.Generator{It,LightQuery.Names{names}}}, Tuple{names}, Tuple{It}} where names where It<:LightQuery.ZippedArrays",
    "page": "LightQuery.jl",
    "title": "LightQuery.columns",
    "category": "method",
    "text": "columns(it)\n\nInverse of rows. Always lazy, see make_columns for eager version.\n\njulia> using LightQuery\n\njulia> (a = [1], b = [1.0]) |>\n        rows |>\n        columns\n(a = [1], b = [1.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.gather",
    "category": "method",
    "text": "gather(it; assignments...)\n\nFor each key => value pair in assignments, gather the Names in value into a single key. Inverse of spread.\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0, c = 1//1) |>\n        gather(_, d = Names(:a, :c))\n(b = 1.0, d = (a = 1, c = 1//1))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.key-Tuple{Pair}",
    "page": "LightQuery.jl",
    "title": "LightQuery.key",
    "category": "method",
    "text": "key(it)\n\nThe key in a key => value pair.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.make_columns-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.make_columns",
    "category": "method",
    "text": "make_columns(it)\n\nCollect into columns. Always eager, see columns lazy version.\n\njulia> using LightQuery\n\njulia> [(a = 1, b = 1.0), (a = 2, b = 2.0)] |>\n        make_columns\n(a = [1, 2], b = [1.0, 2.0])\n\nIf inference cannot detect names, it will use the names of the first item. Map Names over it to override this behavior.\n\njulia> [(a = 1,), (a = 2, b = 2.0)] |>\n        Peek\n|  :a |\n| ---:|\n|   1 |\n|   2 |\n\njulia> @> [(a = 1,), (a = 2, b = 2.0)] |>\n        over(_, Names(:a, :b)) |>\n        Peek\n|  :a |      :b |\n| ---:| -------:|\n|   1 | missing |\n|   2 |     2.0 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.named_tuple-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.named_tuple",
    "category": "method",
    "text": "named_tuple(it)\n\nCoerce to a named_tuple. For performance with working with arbitrary structs, define and @inline propertynames.\n\njulia> using LightQuery\n\njulia> @inline Base.propertynames(p::Pair) = (:first, :second);\n\njulia> named_tuple(:a => 1)\n(first = :a, second = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.order-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.order",
    "category": "method",
    "text": "order(it, call; keywords...)\norder(it, call, condition; keywords...)\n\nGeneralized sort. keywords will be passed to sort!; see the documentation there for options. See By for a way to explicitly mark that an object has been sorted. Most performant if call is type stable, if not, consider using a condition to filter.\n\njulia> using LightQuery\n\njulia> order([2, 1], identity)\n2-element view(::Array{Int64,1}, [2, 1]) with eltype Int64:\n 1\n 2\n\njulia> order([2, 1, missing], identity, !ismissing)\n2-element view(::Array{Union{Missing, Int64},1}, [2, 1]) with eltype Union{Missing, Int64}:\n 1\n 2\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.over-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.over",
    "category": "method",
    "text": "over(it, call)\n\nLazy map with argument order reversed.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.remove-Tuple{Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.remove",
    "category": "method",
    "text": "remove(it, the_names...)\n\nRemove the_names. Inverse of transform.\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0) |>\n        remove(_, :b)\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rename-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.rename",
    "category": "method",
    "text": "rename(it; renames...)\n\nRename it. Because constants do not constant propagate through key-word arguments, wrap with Name.\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0) |>\n        rename(_, c = Name(:a))\n(b = 1.0, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.row_type-Tuple{CSV.File}",
    "page": "LightQuery.jl",
    "title": "LightQuery.row_type",
    "category": "method",
    "text": "row_type(file::CSV.File)\n\nFind the type of a row of a CSV.File if it was converted to a named_tuple. Useful to make type annotations to ensure stability.\n\njulia> using LightQuery\n\njulia> @> \"test.csv\" |>\n        CSV.File(_, allowmissing = :auto) |>\n        row_type\nNamedTuple{(:a, :b),T} where T<:Tuple{Int64,Float64}\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rows-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.rows",
    "category": "method",
    "text": "rows(it)\n\nIterator over rows of a NamedTuple of arrays. Inverse of columns. See Peek for a way to view rows.\n\njulia> using LightQuery\n\njulia> (a = [1, 2], b = [1.0, 2.0]) |>\n        rows |>\n        collect\n2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Float64}},1}:\n (a = 1, b = 1.0)\n (a = 2, b = 2.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.spread-Tuple{Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.spread",
    "category": "method",
    "text": "spread(it::NamedTuple, the_names...)\n\nUnnest nested it in name. Inverse of gather.\n\njulia> using LightQuery\n\njulia> @> (b = 1.0, d = (a = 1, c = 1//1)) |>\n        spread(_, :d)\n(b = 1.0, a = 1, c = 1//1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.transform-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.transform",
    "category": "method",
    "text": "transform(it; assignments...)\n\nMerge assignments into it. Inverse of remove.\n\njulia> using LightQuery\n\njulia> @> (a = 1,) |>\n        transform(_, b = 1.0)\n(a = 1, b = 1.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.unzip-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.unzip",
    "category": "method",
    "text": "unzip(it, n)\n\nUnzip an iterator it which returns tuples of length n. Use Val(n) to guarantee type stability.\n\njulia> using LightQuery\n\njulia> unzip([(1, 1.0), (2, 2.0)], 2)\n([1, 2], [1.0, 2.0])\n\njulia> unzip([(1, 1.0), (2, 2.0)], Val(2))\n([1, 2], [1.0, 2.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.value-Tuple{Pair}",
    "page": "LightQuery.jl",
    "title": "LightQuery.value",
    "category": "method",
    "text": "value(it)\n\nThe value in a key => value pair.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.when-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.when",
    "category": "method",
    "text": "when(it, call)\n\nLazy filter with argument order reversed.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@>-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.@>",
    "category": "macro",
    "text": "macro >(body)\n\nIf body is in the form body_ |> tail_, call @_ on tail, and recur on body.\n\njulia> using LightQuery\n\njulia> @> 0 |> _ - 1 |> abs\n1\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@_-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.@_",
    "category": "macro",
    "text": "macro _(body)\n\nTerser function syntax. The arguments are inside the body; the first argument is _, the second argument is __, etc. Will always @inline.\n\njulia> using LightQuery\n\njulia> (@_ _ + 1)(1)\n2\n\njulia> map((@_ __ - _), (1, 2), (2, 1))\n(1, -1)\n\n\n\n\n\n"
},

{
    "location": "#Autodocs-1",
    "page": "LightQuery.jl",
    "title": "Autodocs",
    "category": "section",
    "text": "Modules = [LightQuery]"
},

]}
