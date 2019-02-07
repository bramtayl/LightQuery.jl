var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "LightQuery.jl",
    "title": "LightQuery.jl",
    "category": "page",
    "text": ""
},

{
    "location": "#LightQuery.By",
    "page": "LightQuery.jl",
    "title": "LightQuery.By",
    "category": "type",
    "text": "By(it, call)\n\nMarks that it has been pre-sorted by the key call. For use with Group or LeftJoin.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Group-Tuple{LightQuery.By}",
    "page": "LightQuery.jl",
    "title": "LightQuery.Group",
    "category": "method",
    "text": "Group(it::By)\n\nGroup consecutive keys in it. Requires a presorted object (see By). Relies on the fact that iteration states can be converted to indices; thus, you might have to define LightQuery.state_to_index for unrecognized types.\n\njulia> using LightQuery\n\njulia> Group(By([1, 3, 2, 4], iseven)) |> collect\n2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:\n 0 => [1, 3]\n 1 => [2, 4]\n\njulia> Group(By([1], iseven)) |> collect\n1-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:\n 0 => [1]\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.LeftJoin",
    "page": "LightQuery.jl",
    "title": "LightQuery.LeftJoin",
    "category": "type",
    "text": "LeftJoin(left::By, right::By)\n\nFor each value in left, look for a value with the same key in right. Requires both to be presorted (see By).\n\njulia> using LightQuery\n\njulia> joined = LeftJoin(\n            By([1, 2, 5, 6], identity),\n            By([1, 3, 4, 6], identity)\n       );\n\njulia> size(joined)\n(4,)\n\njulia> length(joined)\n4\n\njulia> collect(joined)\n4-element Array{Pair{Int64,Union{Missing, Int64}},1}:\n 1 => 1\n 2 => missing\n 5 => missing\n 6 => 6\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Name",
    "page": "LightQuery.jl",
    "title": "LightQuery.Name",
    "category": "type",
    "text": "Name(name)\n\nForce into the type domain. Can also be used as a function to getproperty\n\njulia> using LightQuery\n\njulia> Name(:a)((a = 1,))\n1\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Names-Tuple",
    "page": "LightQuery.jl",
    "title": "LightQuery.Names",
    "category": "method",
    "text": "Names(names...)\n\nForce into the type domain. Can be used to as a function to select columns.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = Names(:a)(x);\n\njulia> @inferred test((a = 1, b = 1.0))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Peek-Union{Tuple{It}, Tuple{It}} where It",
    "page": "LightQuery.jl",
    "title": "LightQuery.Peek",
    "category": "method",
    "text": "Peek(it; max_columns = 7, max_rows = 4)\n\nGet a peek of an iterator which returns named tuples. If inference cannot detect names, it will use the names of the first item. Map a Names object over it to help inference.\n\njulia> using LightQuery\n\njulia> [(a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8)] |>\n        Peek\nShowing 7 of 8 columns\n|  :a |  :b |  :c |  :d |  :e |  :f |  :g |\n| ---:| ---:| ---:| ---:| ---:| ---:| ---:|\n|   1 |   2 |   3 |   4 |   5 |   6 |   7 |\n\njulia> (a = 1:6,) |>\n        rows |>\n        Peek\nShowing 4 of 6 rows\n|  :a |\n| ---:|\n|   1 |\n|   2 |\n|   3 |\n|   4 |\n\njulia> @> (a = 1:2,) |>\n        rows |>\n        when(_, @_ _.a > 1) |>\n        Peek\nShowing at most 4 rows\n|  :a |\n| ---:|\n|   2 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.columns-Union{Tuple{Base.Generator{It,LightQuery.Names{names}}}, Tuple{names}, Tuple{It}} where names where It<:LightQuery.ZippedArrays",
    "page": "LightQuery.jl",
    "title": "LightQuery.columns",
    "category": "method",
    "text": "columns(it)\n\nInverse of rows.\n\njulia> using LightQuery\n\njulia> (a = [1], b = [1.0]) |> rows |> columns\n(a = [1], b = [1.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather-Tuple{Any,Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.gather",
    "category": "method",
    "text": "gather(it, name, names...)\n\nGather all the it in names into a single name. Inverse of spread.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = gather(x, :d, :a, :c);\n\njulia> @inferred test((a = 1, b = 1.0, c = 1//1))\n(b = 1.0, d = (a = 1, c = 1//1))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.in_common-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.in_common",
    "category": "method",
    "text": "in_common(it1, it2)\n\nFind the names in common between it1 and it2.\n\njulia> using LightQuery\n\njulia> in_common((a = 1, b = 1.0), (a = 2, c = 2//2))\n(:a,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.make_columns-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.make_columns",
    "category": "method",
    "text": "make_columns(it)\n\nCollect into columns. See also columns. In same cases, will error if inference cannot detect the names. In this case, use the names of the first row.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> [(a = 1, b = 1.0), (a = 2, b = 2.0)] |>\n        make_columns\n(a = [1, 2], b = [1.0, 2.0])\n\njulia> @> 1:2 |>\n        over(_, x -> error()) |>\n        make_columns\nERROR: Can\'t infer names due to inner function error\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.named_tuple-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.named_tuple",
    "category": "method",
    "text": "named_tuple(it)\n\nCoerce to a named_tuple. For performance with working with arbitrary structs, explicitly define inlined propertynames.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inline Base.propertynames(p::Pair) = (:first, :second);\n\njulia> @inferred named_tuple(:a => 1)\n(first = :a, second = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.order-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.order",
    "category": "method",
    "text": "order(it, call; keywords...)\norder(it, call, condition; keywords...)\n\nGeneralized sort. keywords will be passed to sort!; see the documentation there for options. See By for a way to explicitly mark that an object has been sorted. Most performant if call is type stable, if not, consider using a condition to filter.\n\njulia> using LightQuery\n\njulia> order([2, 1], identity)\n2-element view(::Array{Int64,1}, [2, 1]) with eltype Int64:\n 1\n 2\n\njulia> order([1, 2, missing], identity, !ismissing)\n2-element view(::Array{Union{Missing, Int64},1}, [1, 2]) with eltype Union{Missing, Int64}:\n 1\n 2\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.over-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.over",
    "category": "method",
    "text": "over(it, call)\n\nLazy version of map, with the reverse argument order.\n\njulia> using LightQuery\n\njulia> over([1, 2], x -> x + 0.0) |> collect\n2-element Array{Float64,1}:\n 1.0\n 2.0\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.remove-Tuple{Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.remove",
    "category": "method",
    "text": "remove(it, names...)\n\nRemove names. Inverse of transform.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = remove(x, :b);\n\njulia> @inferred test((a = 1, b = 1.0))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rename-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.rename",
    "category": "method",
    "text": "rename(it; renames::Name...)\n\nRename it. Use Name for type stability; constants don\'t propagate through keyword arguments :(\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = rename(x, c = Name(:a));\n\njulia> @inferred test((a = 1, b = 1.0))\n(b = 1.0, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rows-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.rows",
    "category": "method",
    "text": "rows(it)\n\nIterator over rows of a NamedTuple of arrays. Inverse of columns. See Peek for a way to view rows.\n\njulia> using LightQuery\n\njulia> (a = [1, 2], b = [1.0, 2.0]) |> rows |> Peek\n|  :a |  :b |\n| ---:| ---:|\n|   1 | 1.0 |\n|   2 | 2.0 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.spread-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.spread",
    "category": "method",
    "text": "spread(it::NamedTuple, name)\n\nUnnest nested it in name. Inverse of gather.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = spread(x, :d);\n\njulia> @inferred test((b = 1.0, d = (a = 1, c = 1//1)))\n(b = 1.0, a = 1, c = 1//1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.transform-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.transform",
    "category": "method",
    "text": "transform(it; assignments...)\n\nMerge assignments into it.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred transform((a = 1,), b = 1.0)\n(a = 1, b = 1.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.unzip-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.unzip",
    "category": "method",
    "text": "unzip(it, n)\n\nUnzip an iterator it which returns tuples of length n.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> f(x) = (x, x + 0.0);\n\njulia> test(x) = unzip(x, 2);\n\njulia> test(over([1, missing], f))\n(Union{Missing, Int64}[1, missing], Union{Missing, Float64}[1.0, missing])\n\njulia> @inferred test(zip([1], [1.0]))\n([1], [1.0])\n\njulia> @inferred test([(1, 1.0)])\n([1], [1.0])\n\njulia> test(over(when([1, missing], x -> true), f))\n(Union{Missing, Int64}[1, missing], Union{Missing, Float64}[1.0, missing])\n\njulia> zip([1], [1, 2])\nERROR: ArgumentError: All arrays passed to zip must have the same size\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.when-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.when",
    "category": "method",
    "text": "when(it, call)\n\nLazy version of filter, with the reverse argument order.\n\njulia> using LightQuery\n\njulia> when([1, 2], x -> x > 1) |> collect\n1-element Array{Int64,1}:\n 2\n\n\n\n\n\n"
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
    "text": "macro _(body)\n\nTerser function syntax. The arguments are inside the body; the first argument is _, the second argument is __, etc.\n\njulia> using LightQuery\n\njulia> (@_ _ + 1)(1)\n2\n\njulia> map((@_ __ - _), (1, 2), (2, 1))\n(1, -1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.jl-1",
    "page": "LightQuery.jl",
    "title": "LightQuery.jl",
    "category": "section",
    "text": "Modules = [LightQuery]"
},

{
    "location": "#Tutorial-1",
    "page": "LightQuery.jl",
    "title": "Tutorial",
    "category": "section",
    "text": "I started following the tutorial here here, but got side-tracked by a data cleaning task. You get to see the results, hooray. I\'ve included the flights data in the test folder of this package.I\'ve reexported CSV from the CSV package for convenient IO. We can process the data as we are reading in the file itself! This is because CSV.File returns an iterator.I do a lot of steps here so let\'s break them down:First, I bring in some dates functions, and make them work with missing data.In the CSV.File step, I mark that missing is denoted by \"NA\" in the file. I also specify that I want strings to come in as categorical data.Then I transform each row. First, I convert each row to a named tuple. Then, I combine the scheduled arrival and departure times into a single date-time. The bit at the end about divrem basically means that in a number like 530, hours are in the hundreds place and minutes are in the rest (e.g. 5:30). Then I rename to get rid of abbreviations (you\'ll figure out if you haven\'t already that I\'m a big fan of whole words). Then, I select just the columns we want. I\'ve taken the liberty of ignoring calculated data, that is, data that we can calculate later on. Also, mapping a Names object with over helps Julia out. Julia can\'t infer the names of the rows without this step. This is the because we have two or more type-unstable columns (e.g. departure delay and arrival delay both might be missing).julia> using LightQuery\n\njulia> using Dates: DateTime\n\njulia> import Dates: Minute\n\njulia> Minute(::Missing) = missing;\n\njulia> using Unitful: mi\n\njulia> flight_columns =\n            @> CSV.File(\"flights.csv\", missingstring = \"NA\", categorical = true) |>\n            over(_, @_ @> named_tuple(_) |>\n                transform(_,\n                    departure_time = DateTime(_.year, _.month, _.day,\n                        divrem(_.sched_dep_time, 100)...),\n                    departure_delay = Minute(_.dep_delay),\n                    arrival_time = DateTime(_.year, _.month, _.day,\n                        divrem(_.sched_arr_time, 100)...),\n                    arrival_delay = Minute(_.arr_delay),\n                    distance = _.distance * mi\n                ) |>\n                rename(_,\n                    tail_number = Name(:tailnum),\n                    destination = Name(:dest)\n                )\n            ) |>\n            over(_, Names(:departure_time, :departure_delay, :arrival_time,\n                :arrival_delay, :carrier, :flight, :tail_number, :origin,\n                :destination, :distance)\n            ) |>\n            make_columns;Now that we have our data into Julia, let\'s have a look see. We\'ll start by converting it back to rows, and then taking a Peek. I\'ve taken the liberty of increasing the number of visible columns to 10. The default max Peek size is 7 columns.julia> flights = rows(flight_columns);\n\njulia> Peek(flights, max_columns = 10)\nShowing 4 of 336776 rows\n|     :departure_time | :departure_delay |       :arrival_time | :arrival_delay | :carrier | :flight | :tail_number | :origin | :destination | :distance |\n| -------------------:| ----------------:| -------------------:| --------------:| --------:| -------:| ------------:| -------:| ------------:| ---------:|\n| 2013-01-01T05:15:00 |        2 minutes | 2013-01-01T08:19:00 |     11 minutes |       UA |    1545 |       N14228 |     EWR |          IAH |   1400 mi |\n| 2013-01-01T05:29:00 |        4 minutes | 2013-01-01T08:30:00 |     20 minutes |       UA |    1714 |       N24211 |     LGA |          IAH |   1416 mi |\n| 2013-01-01T05:40:00 |        2 minutes | 2013-01-01T08:50:00 |     33 minutes |       AA |    1141 |       N619AA |     JFK |          MIA |   1089 mi |\n| 2013-01-01T05:45:00 |        -1 minute | 2013-01-01T10:22:00 |    -18 minutes |       B6 |     725 |       N804JB |     JFK |          BQN |   1576 mi |There\'s one more cleaning step we can take. Note that distance is a calculated field. That is, the distance between two locations is always going to be the same. How can we get a clean dataset which only contains the distances between two airports?Let\'s start out by grouping our data by path. Before you group, you MUST sort. Otherwise, you will get incorrect results. Of course, if you have pre-sorted data, no need.julia> by_path =\n            @> flights |>\n            order(_, Names(:origin, :destination)) |>\n            Group(By(_, Names(:origin, :destination))) |>\n            collect;I encourage you to collect after Grouping. This will not use much additional data, it will only store the keys and locations of the groups. Grouping is a little different from dplyr; each group is a pair from key to sub-data-frame:julia> first_group = first(by_path);\n\njulia> first_group.first\n(origin = CategoricalArrays.CategoricalString{UInt32} \"EWR\", destination = CategoricalArrays.CategoricalString{UInt32} \"ALB\")\n\njulia> Peek(first_group.second, max_columns = 10)\nShowing 4 of 439 rows\n|     :departure_time | :departure_delay |       :arrival_time | :arrival_delay | :carrier | :flight | :tail_number | :origin | :destination | :distance |\n| -------------------:| ----------------:| -------------------:| --------------:| --------:| -------:| ------------:| -------:| ------------:| ---------:|\n| 2013-01-01T13:17:00 |       -2 minutes | 2013-01-01T14:23:00 |    -10 minutes |       EV |    4112 |       N13538 |     EWR |          ALB |    143 mi |\n| 2013-01-01T16:21:00 |       34 minutes | 2013-01-01T17:24:00 |     40 minutes |       EV |    3260 |       N19554 |     EWR |          ALB |    143 mi |\n| 2013-01-01T20:04:00 |       52 minutes | 2013-01-01T21:12:00 |     44 minutes |       EV |    4170 |       N12540 |     EWR |          ALB |    143 mi |\n| 2013-01-02T13:27:00 |        5 minutes | 2013-01-02T14:33:00 |    -14 minutes |       EV |    4316 |       N14153 |     EWR |          ALB |    143 mi |So there are 439 flights between Newark (EWR lol) and Albany. The distances are the same, so we really only need the first one. So here\'s what we do: Calling make_columns and then rows will collect our data efficiently.julia> paths =\n        @> by_path |>\n        over(_, @_ first(_.second)) |>\n        over(_, Names(:origin, :destination, :distance)) |>\n        make_columns |>\n        rows;\n\njulia> Peek(paths)\nShowing 4 of 224 rows\n| :origin | :destination | :distance |\n| -------:| ------------:| ---------:|\n|     EWR |          ALB |    143 mi |\n|     EWR |          ANC |   3370 mi |\n|     EWR |          ATL |    746 mi |\n|     EWR |          AUS |   1504 mi |Ok, now let\'s go in reverse, just for fun. How? We need to join back into the original data. Our data that was grouped by path is sorted by the first item, and our path data is sorted by :origin and :destination. Note there are no repeats: we\'ve pregrouped our data. This is important for a left join.julia> joined = LeftJoin(\n            By(by_path, first),\n            By(paths, Names(:origin, :destination))\n        );A join will a row on the left and a row on the right. And the row on the left is a group, so it\'s also got a key and a value.julia> pair = first(joined);\n\njulia> pair.first.first\n(origin = CategoricalArrays.CategoricalString{UInt32} \"EWR\", destination = CategoricalArrays.CategoricalString{UInt32} \"ALB\")\n\njulia> Peek(pair.first.second, max_columns = 10)\nShowing 4 of 439 rows\n|     :departure_time | :departure_delay |       :arrival_time | :arrival_delay | :carrier | :flight | :tail_number | :origin | :destination | :distance |\n| -------------------:| ----------------:| -------------------:| --------------:| --------:| -------:| ------------:| -------:| ------------:| ---------:|\n| 2013-01-01T13:17:00 |       -2 minutes | 2013-01-01T14:23:00 |    -10 minutes |       EV |    4112 |       N13538 |     EWR |          ALB |    143 mi |\n| 2013-01-01T16:21:00 |       34 minutes | 2013-01-01T17:24:00 |     40 minutes |       EV |    3260 |       N19554 |     EWR |          ALB |    143 mi |\n| 2013-01-01T20:04:00 |       52 minutes | 2013-01-01T21:12:00 |     44 minutes |       EV |    4170 |       N12540 |     EWR |          ALB |    143 mi |\n| 2013-01-02T13:27:00 |        5 minutes | 2013-01-02T14:33:00 |    -14 minutes |       EV |    4316 |       N14153 |     EWR |          ALB |    143 mi |\n\njulia> pair.second\n(origin = CategoricalArrays.CategoricalString{UInt32} \"EWR\", destination = CategoricalArrays.CategoricalString{UInt32} \"ALB\", distance = 143 mi)How are we gonna get this all back into a flat data-frame? We need to make use of flatten (which is reexported from Base).julia> @> joined |>\n        over(_, pair -> over(pair.first.second, @_ transform(_, distance_again = pair.second.distance))) |>\n        flatten |>\n        Peek(_, max_columns = 11)\n\nShowing at most 4 rows\n|     :departure_time | :departure_delay |       :arrival_time | :arrival_delay | :carrier | :flight | :tail_number | :origin | :destination | :distance | :distance_again |\n| -------------------:| ----------------:| -------------------:| --------------:| --------:| -------:| ------------:| -------:| ------------:| ---------:| ---------------:|\n| 2013-01-01T13:17:00 |       -2 minutes | 2013-01-01T14:23:00 |    -10 minutes |       EV |    4112 |       N13538 |     EWR |          ALB |    143 mi |          143 mi |\n| 2013-01-01T16:21:00 |       34 minutes | 2013-01-01T17:24:00 |     40 minutes |       EV |    3260 |       N19554 |     EWR |          ALB |    143 mi |          143 mi |\n| 2013-01-01T20:04:00 |       52 minutes | 2013-01-01T21:12:00 |     44 minutes |       EV |    4170 |       N12540 |     EWR |          ALB |    143 mi |          143 mi |\n| 2013-01-02T13:27:00 |        5 minutes | 2013-01-02T14:33:00 |    -14 minutes |       EV |    4316 |       N14153 |     EWR |          ALB |    143 mi |          143 mi |Look! The distances match. Hooray!"
},

]}
