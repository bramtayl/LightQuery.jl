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
    "text": "By(it, f)\n\nMarks that it has been pre-sorted by the key f. For use with Group or LeftJoin.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Group-Tuple{LightQuery.By}",
    "page": "LightQuery.jl",
    "title": "LightQuery.Group",
    "category": "method",
    "text": "Group(b::By)\n\nGroup consecutive keys in b. Requires a presorted object (see By). Relies on the fact that iteration states can be converted to indices; thus, you might have to define LightQuery.state_to_index for unrecognized types (PR\'s welcome.)\n\njulia> using LightQuery\n\njulia> Group(By([1, 3, 2, 4], iseven)) |> first\nfalse => [1, 3]\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.LeftJoin",
    "page": "LightQuery.jl",
    "title": "LightQuery.LeftJoin",
    "category": "type",
    "text": "LeftJoin(left::By, right::By)\n\nFor each value in left, look for a value with the same key in right. Requires both to be presorted (see By).\n\njulia> using LightQuery\n\njulia> LeftJoin(\n            By([1, 2, 5, 6], identity),\n            By([1, 3, 4, 6], identity)\n       ) |> collect\n4-element Array{Pair{Int64,Union{Missing, Int64}},1}:\n 1 => 1\n 2 => missing\n 5 => missing\n 6 => 6\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Name",
    "page": "LightQuery.jl",
    "title": "LightQuery.Name",
    "category": "type",
    "text": "Name(x)\n\nForce into the type domain. Can also be used as a function.\n\njulia> using LightQuery\n\njulia> Name(:a)((a = 1,))\n1\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Names-Tuple",
    "page": "LightQuery.jl",
    "title": "LightQuery.Names",
    "category": "method",
    "text": "Names(names...)\n\nNames in the type domain. Can be used to select columns.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = Names(:a)(x);\n\njulia> @inferred test((a = 1, b = 2.0))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Peek-Union{Tuple{It}, Tuple{It}} where It",
    "page": "LightQuery.jl",
    "title": "LightQuery.Peek",
    "category": "method",
    "text": "Peek(it)\n\nIf it is over](@ref) Names, LightQuery will automatically show you a peek of the data in table form. However, not all iterators which yield NamedTuples will print this way; in order to get a peek of them, you need to explicitly use Peek. In same cases, will error if inference cannot detect the names. In this case, map a Names object over it first.\n\njulia> using LightQuery\n\njulia> rows((a = [1, 1.0], b = [2, 2.0])) |> Peek\n|  :a |  :b |\n| ---:| ---:|\n| 1.0 | 2.0 |\n| 1.0 | 2.0 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.columns-Union{Tuple{Base.Generator{It,LightQuery.Names{Symbols}}}, Tuple{Symbols}, Tuple{It}} where Symbols where It<:Base.Iterators.Zip",
    "page": "LightQuery.jl",
    "title": "LightQuery.columns",
    "category": "method",
    "text": "columns(it)\n\nInverse of rows.\n\njulia> using LightQuery\n\njulia> columns(rows((a = [1, 1.0], b = [2, 2.0])))\n(a = [1.0, 1.0], b = [2.0, 2.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather-Tuple{Any,Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.gather",
    "category": "method",
    "text": "gather(data, name, names...)\n\nGather all the data in names into a single name. Inverse of spread.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = gather(x, :d, :a, :c);\n\njulia> @inferred test((a = 1, b = 2.0, c = \"c\"))\n(b = 2.0, d = (a = 1, c = \"c\"))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.in_common-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.in_common",
    "category": "method",
    "text": "in_common(data1, data2)\n\nFind the names in common between data1 and data2.\n\njulia> using LightQuery\n\njulia> in_common((a = 1, b = 2.0), (a = 1, c = 3.0))\n(:a,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.make_columns-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.make_columns",
    "category": "method",
    "text": "make_columns(it)\n\nCollect into columns. See also columns. In same cases, will error if inference cannot detect the names. In this case, map a Names object over it first.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> (a = [1, 2], b = [1.0, 2.0]) |>\n        rows |>\n        make_columns\n(a = [1, 2], b = [1.0, 2.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.named_tuple-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.named_tuple",
    "category": "method",
    "text": "named_tuple(x)\n\nCoerce to a named_tuple. For performance with working with arbitrary structs, explicitly define inlined propertynames.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inline Base.propertynames(p::Pair) = (:first, :second);\n\njulia> @inferred named_tuple(:a => 1)\n(first = :a, second = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.order-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.order",
    "category": "method",
    "text": "order(it, f; kwargs...)\norder(it, f, condition; kwargs...)\n\nGeneralized sort. kwargs will be passed to sort!; see the documentation there for options. See By for a way to explicitly mark that an object has been sorted. Most performant it f is type stable, if not, consider using a condition to filter.\n\njulia> using LightQuery\n\njulia> order([\"b\", \"a\"], identity)\n2-element view(::Array{String,1}, [2, 1]) with eltype String:\n \"a\"\n \"b\"\n\njulia> order([missing, \"a\"], identity, !ismissing)\n1-element view(::Array{Union{Missing, String},1}, [2]) with eltype Union{Missing, String}:\n \"a\"\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.over-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.over",
    "category": "method",
    "text": "over(it, f)\n\nLazy version of map, with the reverse argument order.\n\njulia> using LightQuery\n\njulia> over([1, 2], x -> x + 1) |> collect\n2-element Array{Int64,1}:\n 2\n 3\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.remove-Tuple{Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.remove",
    "category": "method",
    "text": "remove(data, names...)\n\nRemove names. Inverse of transform.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = remove(x, :b);\n\njulia> @inferred test((a = 1, b = 2.0))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rename-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.rename",
    "category": "method",
    "text": "rename(data; renames...)\n\nRename data. Use Name for type stability; constants don\'t propagate through keyword arguments.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = rename(x, c = Name(:a));\n\njulia> @inferred test((a = 1, b = 2.0))\n(b = 2.0, c = 1)\n\njulia> rename((a = 1, b = 2.0), c = :a)\n(b = 2.0, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rows-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.rows",
    "category": "method",
    "text": "rows(n::NamedTuple)\n\nIterator over rows of a NamedTuple of names. Inverse of columns.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> rows((a = [1, 2], b = [2, 1]))\n|  :a |  :b |\n| ---:| ---:|\n|   1 |   2 |\n|   2 |   1 |\n\njulia> rows((a = 1:6,))\nShowing 4 of 6 rows\n|  :a |\n| ---:|\n|   1 |\n|   2 |\n|   3 |\n|   4 |\n\njulia> rows((a = [1], b = [2], c = [3], d = [4], e = [5], f = [6], g = [7], h = [8]))\nShowing 7 of 8 columns\n|  :a |  :b |  :c |  :d |  :e |  :f |  :g |\n| ---:| ---:| ---:| ---:| ---:| ---:| ---:|\n|   1 |   2 |   3 |   4 |   5 |   6 |   7 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.spread-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.spread",
    "category": "method",
    "text": "spread(data::NamedTuple, name)\n\nUnnest nested data in name. Inverse of gather.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = spread(x, :d);\n\njulia> @inferred test((b = 2.0, d = (a = 1, c = \"c\")))\n(b = 2.0, a = 1, c = \"c\")\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.transform-Tuple{NamedTuple}",
    "page": "LightQuery.jl",
    "title": "LightQuery.transform",
    "category": "method",
    "text": "transform(data; assignments...)\n\nMerge assignments into data.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred transform((a = 1, b = 2.0), c = \"3\")\n(a = 1, b = 2.0, c = \"3\")\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.unzip-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.unzip",
    "category": "method",
    "text": "unzip(it, n)\n\nUnzip an iterator it which returns tuples of length n.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> f(x) = (x, x + 1.0);\n\njulia> unzip(over([1], f), 2)\n([1], [2.0])\n\njulia> unzip(over([1, missing], f), 2)\n(Union{Missing, Int64}[1, missing], Union{Missing, Float64}[2.0, missing])\n\njulia> unzip(zip([1], [1.0]), 2)\n([1], [1.0])\n\njulia> unzip([(1, 1.0)], 2)\n([1], [1.0])\n\njulia> unzip(over(when([1, missing, 2], x -> ismissing(x) || x > 1), f), 2)\n(Union{Missing, Int64}[missing, 2], Union{Missing, Float64}[missing, 3.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.when-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.when",
    "category": "method",
    "text": "when(it, f)\n\nLazy version of filter, with the reverse argument order.\n\njulia> using LightQuery\n\njulia> when([1, 2], x -> x > 1) |> collect\n1-element Array{Int64,1}:\n 2\n\n\n\n\n\n"
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
    "text": "macro _(body)\n\nTerser function syntax. The arguments are inside the body; the first argument is _, the second argument is __, etc.\n\njulia> using LightQuery\n\njulia> 1 |> @_(_ + 1)\n2\n\njulia> map(@_(__ - _), (1, 2), (2, 1))\n(1, -1)\n\n\n\n\n\n"
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
    "text": "For an example of how to use this package, see the demo below, which follows the example here.A copy of the flights data is included in the test folder of this package. I\'ve reexported CSV from the CSV package for convenient IO. The data comes in as a data frame, but you can easily convert most objects to named tuples using named_tuple. I recollect to remove extra missing annotations unhelpfully provided by CSV.julia> using LightQuery\n\njulia> flight_columns =\n        @> CSV.read(\"flights.csv\", missingstring = \"NA\") |>\n        named_tuple |>\n        map(x -> collect(over(x, identity)), _);As a named tuple, the data will be in a column-wise form; lazily convert it to rows.julia> flights = rows(flight_columns)\nShowing 7 of 19 columns\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |You can lazily filter data with when.julia> using LightQuery\n\njulia> @> flights |>\n        when(_, @_ _.month == 1 && _.day == 1)\nShowing 7 of 19 columns\nShowing at most 4 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |You might find it more efficient to do this columns-wise:julia> using LightQuery\n\njulia> @> flight_columns |>\n        (_.month .== 1) .& (_.day .== 1) |>\n        view(flights, _)\nShowing 7 of 19 columns\nShowing 4 of 842 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |You can order the flights, using Names to select columns.julia> using MappedArrays: mappedarray\n\njulia> get_date = Names(:year, :month, :day)\nNames{(:year, :month, :day)}()\n\njulia> by_date =\n        @> flights |>\n        order(_, get_date)\nShowing 7 of 19 columns\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |You can also pass in keyword arguments to sort! via order, like rev = true. Note also that arr_delay includes missing data. For performance, I\'m adding a condition to remove the missing data. This will be a common pattern.julia> @> flights |>\n        order(_, Names(:arr_delay), (@_ !ismissing(_.arr_delay)), rev = true)\nShowing 7 of 19 columns\nShowing 4 of 327346 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      1 |    9 |       641 |             900 |       1301 |      1242 |\n|  2013 |      6 |   15 |      1432 |            1935 |       1137 |      1607 |\n|  2013 |      1 |   10 |      1121 |            1635 |       1126 |      1239 |\n|  2013 |      9 |   20 |      1139 |            1845 |       1014 |      1457 |In the original column-wise form, you can select with Names. Then, use rows again to print.julia> get_date(flight_columns) |>\n          rows\nShowing 4 of 336776 rows\n| :year | :month | :day |\n| -----:| ------:| ----:|\n|  2013 |      1 |    1 |\n|  2013 |      1 |    1 |\n|  2013 |      1 |    1 |\n|  2013 |      1 |    1 |You can also remove columns in the column-wise form.julia> @> flight_columns |>\n        remove(_, :year, :month, :day) |>\n        rows\nShowing 7 of 16 columns\nShowing 4 of 336776 rows\n| :dep_time | :sched_dep_time | :dep_delay | :arr_time | :sched_arr_time | :arr_delay | :carrier |\n| ---------:| ---------------:| ----------:| ---------:| ---------------:| ----------:| --------:|\n|       517 |             515 |          2 |       830 |             819 |         11 |       UA |\n|       533 |             529 |          4 |       850 |             830 |         20 |       UA |\n|       542 |             540 |          2 |       923 |             850 |         33 |       AA |\n|       544 |             545 |         -1 |      1004 |            1022 |        -18 |       B6 |You can also rename columns. Because constants (currently) do not propagate through keyword arguments in Julia, it\'s smart to wrap column names with Name.julia> @> flight_columns |>\n        rename(_, tail_num = Name(:tailnum)) |>\n        rows\nShowing 7 of 19 columns\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |You can add new columns with transform. If you want to refer to previous columns, you\'ll have to transform twice. You can do this row-wise. Note that I\'ve added a second over simply to specify the names of the items. This will be a common pattern for when inference can\'t keep track of names.julia> @> flights |>\n        over(_, @_ @> transform(_,\n            gain = _.arr_delay - _.dep_delay,\n            speed = _.distance / _.air_time * 60\n        ) |> transform(_,\n            gain_per_hour = _.gain ./ (_.air_time / 60)\n        )) |>\n        over(_, Names(propertynames(flight_columns)..., :gain, :speed,\n            :gain_per_hour))\nShowing 7 of 22 columns\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |You can also do the same thing column-wise:julia> @> flight_columns |>\n        transform(_,\n            gain = _.arr_delay .- _.dep_delay,\n            speed = _.distance ./ _.air_time .* 60\n        ) |>\n        transform(_,\n            gain_per_hour = _.gain ./ (_.air_time / 60)\n        ) |>\n        rows\nShowing 7 of 22 columns\nShowing 4 of 336776 rows\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      1 |    1 |       517 |             515 |          2 |       830 |\n|  2013 |      1 |    1 |       533 |             529 |          4 |       850 |\n|  2013 |      1 |    1 |       542 |             540 |          2 |       923 |\n|  2013 |      1 |    1 |       544 |             545 |         -1 |      1004 |You can\'t summarize ungrouped data, but you can just directly access columns:julia> using Statistics: mean;\n\njulia> mean(skipmissing(flight_columns.dep_delay))\n12.639070257304708I don\'t provide a export a sample function here, but StatsBase does.Grouping here works differently than in dplyr:You can only Group sorted data. To let Julia know that the data has been sorted, you need to explicitly wrap the data with By.\nGroups return a pair, key => sub-data-frame. So:julia> by_tailnum =\n        @> flights |>\n        order(_, Names(:tailnum), (@_ !ismissing(_.tailnum))) |>\n        Group(By(_, Names(:tailnum)));\n\njulia> first(by_tailnum)\n(tailnum = \"D942DN\",) => Showing 7 of 19 columns\n| :year | :month | :day | :dep_time | :sched_dep_time | :dep_delay | :arr_time |\n| -----:| ------:| ----:| ---------:| ---------------:| ----------:| ---------:|\n|  2013 |      2 |   11 |      1508 |            1400 |         68 |      1807 |\n|  2013 |      3 |   23 |      1340 |            1300 |         40 |      1638 |\n|  2013 |      3 |   24 |       859 |             835 |         24 |      1142 |\n|  2013 |      7 |    5 |      1253 |            1259 |         -6 |      1518 |You can play around with the pair structure of groups to coerce it to the shape you want. Notice that I\'m collecting after the Group (for performance). I\'m also explicitly calling Peek here; Julia can only guess that you want a peek if over was used with a Names object.julia> @> by_tailnum |>\n        collect |>\n        over(_, @_ transform(_.first,\n            count = length(_.second),\n            distance = columns(_.second).distance |> mean,\n            delay = columns(_.second).arr_delay |> skipmissing |> mean\n        )) |>\n        Peek\nShowing 4 of 4043 rows\n| :tailnum | :count |         :distance |             :delay |\n| --------:| ------:| -----------------:| ------------------:|\n|   D942DN |      4 |             854.5 |               31.5 |\n|   N0EGMQ |    371 |  676.188679245283 |  9.982954545454545 |\n|   N10156 |    153 | 757.9477124183006 | 12.717241379310344 |\n|   N102UW |     48 |           535.875 |             2.9375 |For the n-distinct example, I\'ve switched things around to be just a smidge more efficient. This example shows how calling make_columns and then rows is sometimes necessary to trigger eager evaluation. I\'ve also defined a count_flights function because we\'ll be using it again.julia> count_flights(x) = over(x, @_ transform(_.first,\n            flights = length(_.second)\n        ));\n\njulia> @> flights |>\n        order(_, Names(:dest, :tailnum), (@_ !ismissing(_.tailnum))) |>\n        Group(By(_, Names(:dest, :tailnum))) |>\n        collect |>\n        count_flights |>\n        make_columns |>\n        rows |>\n        Group(By(_, Names(:dest))) |>\n        over(_, @_ transform(_.first,\n            planes = length(_.second),\n            flights = sum(columns(_.second).flights)\n        )) |>\n        Peek\nShowing at most 4 rows\n| :dest | :planes | :flights |\n| -----:| -------:| --------:|\n|   ABQ |     108 |      254 |\n|   ACK |      58 |      265 |\n|   ALB |     172 |      439 |\n|   ANC |       6 |        8 |Of course, you can group repeatedly. You don\'t have to reorder each time if you do this.julia> grouped_by_date =\n        @> by_date |>\n        Group(By(_, get_date)) |>\n        collect;\n\njulia> per_day =\n        @> grouped_by_date |>\n        count_flights |>\n        make_columns |>\n        rows\nShowing 4 of 365 rows\n| :year | :month | :day | :flights |\n| -----:| ------:| ----:| --------:|\n|  2013 |      1 |    1 |      842 |\n|  2013 |      1 |    2 |      943 |\n|  2013 |      1 |    3 |      914 |\n|  2013 |      1 |    4 |      915 |\n\njulia> sum_flights(x) = over(x, @_ transform(_.first,\n            flights = sum(columns(_.second).flights)\n        ));\n\njulia> per_month =\n        @> per_day |>\n        Group(By(_, Names(:year, :month))) |>\n        collect |>\n        sum_flights |>\n        make_columns |>\n        rows\nShowing 4 of 12 rows\n| :year | :month | :flights |\n| -----:| ------:| --------:|\n|  2013 |      1 |    27004 |\n|  2013 |      2 |    24951 |\n|  2013 |      3 |    28834 |\n|  2013 |      4 |    28330 |\n\njulia> @> per_month |>\n          Group(By(_, Names(:year))) |>\n          sum_flights |>\n          Peek\nShowing at most 4 rows\n| :year | :flights |\n| -----:| --------:|\n|  2013 |   336776 |Here\'s the example in the dplyr docs for piping:julia> @> grouped_by_date |>\n        over(_, @_ transform(_.first,\n            arr = columns(_.second).arr_delay |> skipmissing |> mean,\n            dep = columns(_.second).dep_delay |> skipmissing |> mean\n        )) |>\n        when(_, @_ _.arr > 30 || _.dep > 30) |>\n        over(_, Names(:year, :month, :day, :arr, :dep))\nShowing at most 4 rows\n| :year | :month | :day |               :arr |               :dep |\n| -----:| ------:| ----:| ------------------:| ------------------:|\n|  2013 |      1 |   16 |  34.24736225087925 | 24.612865497076022 |\n|  2013 |      1 |   31 | 32.602853745541026 | 28.658362989323845 |\n|  2013 |      2 |   11 |  36.29009433962264 |  39.07359813084112 |\n|  2013 |      2 |   27 |  31.25249169435216 |  37.76327433628319 |"
},

{
    "location": "#Two-table-verbs-1",
    "page": "LightQuery.jl",
    "title": "Two table verbs",
    "category": "section",
    "text": "I\'m following the example here.Again, for inference reasons, natural joins won\'t work. I only provide one join at the moment, but it\'s super efficient. Let\'s start by reading in airlines and letting julia know that it\'s already sorted by :carrier.julia> airlines =\n        @> CSV.read(\"airlines.csv\", missingstring = \"NA\") |>\n        named_tuple |>\n        map(x -> collect(over(x, identity)), _) |>\n        rows |>\n        By(_, Names(:carrier));If we want to join this data into the flights data, here\'s what we do. LeftJoin requires not only presorted but unique keys. Of course, there are multiple flights from the same airline, so we need to group first. Then, we tell Julia that the groups are themselves sorted (by the first item, the key). Finally we can join in the airline data. But the results are a bit tricky. Let\'s take a look at the first item. Just like the dplyr manual, I\'m only using a few of the columns from flights for demonstration.julia> flight2_columns =\n        @> flight_columns |>\n        Names(:year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier)(_);\n\njulia> flights2 = rows(flight2_columns)\nShowing 7 of 8 columns\nShowing 4 of 336776 rows\n| :year | :month | :day | :hour | :origin | :dest | :tailnum |\n| -----:| ------:| ----:| -----:| -------:| -----:| --------:|\n|  2013 |      1 |    1 |     5 |     EWR |   IAH |   N14228 |\n|  2013 |      1 |    1 |     5 |     LGA |   IAH |   N24211 |\n|  2013 |      1 |    1 |     5 |     JFK |   MIA |   N619AA |\n|  2013 |      1 |    1 |     5 |     JFK |   BQN |   N804JB |\n\njulia> airline_join =\n        @> flights2 |>\n        order(_, Names(:carrier)) |>\n        Group(By(_, Names(:carrier))) |>\n        By(_, first) |>\n        LeftJoin(_, airlines);\n\njulia> first(airline_join)\n((carrier = \"9E\",)=>Showing 7 of 8 columns\nShowing 4 of 18460 rows\n| :year | :month | :day | :hour | :origin | :dest | :tailnum |\n| -----:| ------:| ----:| -----:| -------:| -----:| --------:|\n|  2013 |      1 |    1 |     8 |     JFK |   MSP |   N915XJ |\n|  2013 |      1 |    1 |    15 |     JFK |   IAD |   N8444F |\n|  2013 |      1 |    1 |    14 |     JFK |   BUF |   N920XJ |\n|  2013 |      1 |    1 |    15 |     JFK |   SYR |   N8409N |\n) => (carrier = \"9E\", name = \"Endeavor Air Inc.\")We end up getting a group and subframe on the left, and a row on the right.If you want to collect your results into a flat new dataframe, you need to do a bit of surgery, including making use of flatten (which I reexport from Base). We also need to make a fake row to insert on the right in case we can\'t find a match.julia> @> airline_join |>\n        over(_, @_ over(_.first.second, x -> merge(x, _.second))) |>\n        flatten |>\n        over(_, Names(:year, :month, :day, :hour, :origin, :dest, :tailnum,\n            :carrier, :name))\nShowing 7 of 9 columns\nShowing at most 4 rows\n| :year | :month | :day | :hour | :origin | :dest | :tailnum |\n| -----:| ------:| ----:| -----:| -------:| -----:| --------:|\n|  2013 |      1 |    1 |     8 |     JFK |   MSP |   N915XJ |\n|  2013 |      1 |    1 |    15 |     JFK |   IAD |   N8444F |\n|  2013 |      1 |    1 |    14 |     JFK |   BUF |   N920XJ |\n|  2013 |      1 |    1 |    15 |     JFK |   SYR |   N8409N |Let\'s keep going in the examples. I\'m going to read in the weather data, and let Julia know that it has already been sorted.julia> weather_columns =\n        @> CSV.read( \"weather.csv\", missingstring = \"NA\") |>\n        named_tuple |>\n        map(x -> collect(over(x, identity)), _);\n\njulia> weather =\n        @> weather_columns |>\n        rows |>\n        By(_, Names(:origin, :year, :month, :day, :hour));Unfortunately, we have to deal with another problem: there\'s gaps in the weather data. We need to make a missing row of data. I\'m also going to use union to get all the names together.julia> const missing_weather =\n        @> weather_columns |>\n        remove(_, :origin, :year, :month, :day, :hour) |>\n        map(x -> missing, _);\n\njulia> weather_join =\n        @> flights2 |>\n        order(_, Names(:origin, :year, :month, :day, :hour)) |>\n        Group(By(_, Names(:origin, :year, :month, :day, :hour))) |>\n        By(_, first) |>\n        LeftJoin(_, weather);\n\njulia> flight2_and_weather_names = Names(union(\n            propertynames(flight2_columns),\n            propertynames(weather_columns)\n        )...);\n\njulia> @> weather_join |>\n        over(_, @_ over(_.first.second, x -> merge(x, coalesce(_.second, missing_weather)))) |>\n        flatten |>\n        over(_, flight2_and_weather_names)\nShowing 7 of 18 columns\nShowing at most 4 rows\n| :year | :month | :day | :hour | :origin | :dest | :tailnum |\n| -----:| ------:| ----:| -----:| -------:| -----:| --------:|\n|  2013 |      1 |    1 |     5 |     EWR |   IAH |   N14228 |\n|  2013 |      1 |    1 |     5 |     EWR |   ORD |   N39463 |\n|  2013 |      1 |    1 |     6 |     EWR |   FLL |   N516JB |\n|  2013 |      1 |    1 |     6 |     EWR |   SFO |   N53441 |Of course, if you wanted, you could just remove the rows with missing weather data, essentially doing an inner join:julia> @> weather_join |>\n        when(_, @_ _.second !== missing) |>\n        over(_, @_ over(_.first.second, x -> merge(x, missing_weather))) |>\n        flatten |>\n        over(_, flight2_and_weather_names)\nShowing 7 of 18 columns\nShowing at most 4 rows\n| :year | :month | :day | :hour | :origin | :dest | :tailnum |\n| -----:| ------:| ----:| -----:| -------:| -----:| --------:|\n|  2013 |      1 |    1 |     5 |     EWR |   IAH |   N14228 |\n|  2013 |      1 |    1 |     5 |     EWR |   ORD |   N39463 |\n|  2013 |      1 |    1 |     6 |     EWR |   FLL |   N516JB |\n|  2013 |      1 |    1 |     6 |     EWR |   SFO |   N53441 |"
},

]}
