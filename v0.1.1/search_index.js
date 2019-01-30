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
    "text": "group(b::By)\n\nGroup consecutive keys in b. Requires a presorted object (see By).\n\njulia> using LightQuery\n\njulia> Group(By([1, 3, 2, 4], iseven)) |> first\nfalse => [1, 3]\n\n\n\n\n\n"
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
    "location": "#LightQuery.columns-Tuple{Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.columns",
    "category": "method",
    "text": "columns(it, names...)\n\nCollect into columns. Inverse of rows. Unfortunately, you must specity names; sometimes, autocolumns will be able to detect them for you and run column-wise optimizations.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = columns(x, :b, :a);\n\njulia> @inferred test([(a = 1, b = 1.0)])\n(b = [1.0], a = [1])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather-Tuple{Any,Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.gather",
    "category": "method",
    "text": "gather(data, name, names...)\n\nGather all the data in names into a single name. Inverse of spread.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = gather(x, :d, :a, :c);\n\njulia> @inferred test((a = 1, b = 2.0, c = \"c\"))\n(b = 2.0, d = (a = 1, c = \"c\"))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.named_tuple-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.named_tuple",
    "category": "method",
    "text": "named_tuple(x)\n\nCoerce to a named_tuple. For performance with working with arbitrary structs, explicitly define public propertynames.\n\njulia> using LightQuery\n\njulia> Base.propertynames(p::Pair) = (:first, :second);\n\njulia> named_tuple(:a => 1)\n(first = :a, second = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.order-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.order",
    "category": "method",
    "text": "order(it, f; kwargs...)\n\nGeneralized sort. kwargs will be passed to sort!; see the documentation there for options. See By for a way to explicitly mark that an object has been sorted.\n\njulia> using LightQuery\n\njulia> order([\"b\", \"a\"], identity)\n2-element view(::Array{String,1}, [2, 1]) with eltype String:\n \"a\"\n \"b\"\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.over-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.over",
    "category": "method",
    "text": "over(it, f)\n\nBase.Generator with the reverse argument order.\n\njulia> using LightQuery\n\njulia> over([1, 2], x -> x + 1) |> collect\n2-element Array{Int64,1}:\n 2\n 3\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.pretty-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.pretty",
    "category": "method",
    "text": "pretty(x)\n\nPretty display.\n\njulia> using LightQuery\n\njulia> pretty((a = [1, 2], b = [1.0, 2.0]))\n2×2 DataFrames.DataFrame\n│ Row │ a     │ b       │\n│     │ Int64 │ Float64 │\n├─────┼───────┼─────────┤\n│ 1   │ 1     │ 1.0     │\n│ 2   │ 2     │ 2.0     │\n\n\n\n\n\n"
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
    "text": "rename(data; renames...)\n\nRename data. Currently unstable without Name\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = rename(x, c = Name(:a));\n\njulia> @inferred test((a = 1, b = 2.0))\n(b = 2.0, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rows-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.rows",
    "category": "method",
    "text": "rows(n::NamedTuple)\n\nIterator over rows of a NamedTuple of names. Inverse of columns.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred first(rows((a = [1, 2], b = [2, 1])))\n(a = 1, b = 2)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.select-Tuple{Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.select",
    "category": "method",
    "text": "select(data::NamedTuple, names...)\n\nSelect names.\n\nselect(ss::Symbol...)\n\nCurried form.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = select(x, :a);\n\njulia> @inferred test((a = 1, b = 2.0))\n(a = 1,)\n\njulia> test(x) = select(:a)(x);\n\njulia> @inferred test((a = 1, b = 2.0))\n(a = 1,)\n\n\n\n\n\n"
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
    "text": "unzip(it, n)\n\nUnzip an iterator it which returns tuples of length n.\n\njulia> using LightQuery\n\njulia> f(x) = (x, x + 1.0);\n\njulia> unzip(over([1], f), 2)\n([1], [2.0])\n\njulia> unzip(over([1, missing], f), 2)\n(Union{Missing, Int64}[1, missing], Union{Missing, Float64}[2.0, missing])\n\njulia> unzip(zip([1], [1.0]), 2)\n([1], [1.0])\n\njulia> unzip([(1, 1.0)], 2)\n([1], [1.0])\n\njulia> unzip(over(when([1, missing, 2], x -> ismissing(x) || x > 1), f), 2)\n(Union{Missing, Int64}[missing, 2], Union{Missing, Float64}[missing, 3.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.when-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.when",
    "category": "method",
    "text": "when(it, f)\n\nBase.Iterators.Filter with the reverse argument order.\n\njulia> using LightQuery\n\njulia> when([1, 2], x -> x > 1) |> collect\n1-element Array{Int64,1}:\n 2\n\n\n\n\n\n"
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
    "text": "For an example of how to use this package, see the demo below, which follows the example here. A copy of the flights data is included in the test folder of this package.The biggest difference between this package and dplyr is that you have to explicitly move your data back and forth between rows (a vector of named tuples) and columns (a named tuple of vectors) depending on the kind of operation you want to do. Another inconvenience is that when you are moving from rows to columns, in many cases, you will have to re-specify the column names (except in certain cases). This is inconvenient but prevents this package from having to rely on inference.You can easily convert most objects to named tuples using named_tuple. As a named tuple, the data will be in a column-wise form. If you want to display it, you can use pretty to hack the show methods of DataFrames.So read in flights, convert it into a named tuple, and remove the row-number column (which reads in without a name). This package comes with its own chaining macro @>, which I\'ll make heavy use of. I\'ve reexported CSV from the CSV package for convenient IO.julia> using LightQuery\n\njulia> flights =\n          @> CSV.read(\"flights.csv\", missingstring = \"NA\") |>\n          named_tuple |>\n          remove(_, Symbol(\"\"));\n\njulia> pretty(flights)\n336776×19 DataFrames.DataFrame. Omitted printing of 13 columns\n│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │\n│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │\n├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤\n│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │\n│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │\n│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │\n│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │\n│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │\n│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │\n│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │\n⋮\n│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │\n│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │\n│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │\n│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │\n│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │\n│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │\n│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │\n│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │The rows iterator will convert the data to row-wise form. when will filter the data. You can make anonymous functions  with @_.To display row-wise data, first, convert back to a columns-wise format with autocolumns.julia> using LightQuery\n\njulia> @> flights |>\n          rows |>\n          when(_, @_ _.month == 1 && _.day == 1) |>\n          autocolumns |>\n          pretty\n842×19 DataFrames.DataFrame. Omitted printing of 13 columns\n│ Row │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │\n│     │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │\n├─────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤\n│ 1   │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │\n│ 2   │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │\n│ 3   │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │\n│ 4   │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │\n│ 5   │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │\n│ 6   │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │\n│ 7   │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │\n⋮\n│ 835 │ 2013   │ 1      │ 1      │ 2343     │ 1724           │ 379       │\n│ 836 │ 2013   │ 1      │ 1      │ 2353     │ 2359           │ -6        │\n│ 837 │ 2013   │ 1      │ 1      │ 2353     │ 2359           │ -6        │\n│ 838 │ 2013   │ 1      │ 1      │ 2356     │ 2359           │ -3        │\n│ 839 │ 2013   │ 1      │ 1      │ missing  │ 1630           │ missing   │\n│ 840 │ 2013   │ 1      │ 1      │ missing  │ 1935           │ missing   │\n│ 841 │ 2013   │ 1      │ 1      │ missing  │ 1500           │ missing   │\n│ 842 │ 2013   │ 1      │ 1      │ missing  │ 600            │ missing   │You can arrange rows with order. Here, the currying version of select comes in handy.julia> by_date =\n          @> flights |>\n          rows |>\n          order(_, select(:year, :month, :day));\n\njulia> @> by_date |>\n          autocolumns |>\n          pretty\n336776×19 DataFrames.DataFrame. Omitted printing of 13 columns\n│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │\n│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │\n├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤\n│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │\n│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │\n│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │\n│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │\n│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │\n│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │\n│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │\n⋮\n│ 336769 │ 2013   │ 12     │ 31     │ missing  │ 1500           │ missing   │\n│ 336770 │ 2013   │ 12     │ 31     │ missing  │ 1430           │ missing   │\n│ 336771 │ 2013   │ 12     │ 31     │ missing  │ 855            │ missing   │\n│ 336772 │ 2013   │ 12     │ 31     │ missing  │ 705            │ missing   │\n│ 336773 │ 2013   │ 12     │ 31     │ missing  │ 825            │ missing   │\n│ 336774 │ 2013   │ 12     │ 31     │ missing  │ 1615           │ missing   │\n│ 336775 │ 2013   │ 12     │ 31     │ missing  │ 600            │ missing   │\n│ 336776 │ 2013   │ 12     │ 31     │ missing  │ 830            │ missing   │You can also pass in keyword arguments to sort! via order, like rev = true. The difference from the dplyr output here is caused by how sort! handles missing data in Julia (I think).julia> @> flights |>\n          rows |>\n          order(_, select(:arr_delay), rev = true) |>\n          autocolumns |>\n          pretty\n336776×19 DataFrames.DataFrame. Omitted printing of 13 columns\n│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │\n│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │\n├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤\n│ 1      │ 2013   │ 1      │ 1      │ 1525     │ 1530           │ -5        │\n│ 2      │ 2013   │ 1      │ 1      │ 1528     │ 1459           │ 29        │\n│ 3      │ 2013   │ 1      │ 1      │ 1740     │ 1745           │ -5        │\n│ 4      │ 2013   │ 1      │ 1      │ 1807     │ 1738           │ 29        │\n│ 5      │ 2013   │ 1      │ 1      │ 1939     │ 1840           │ 59        │\n│ 6      │ 2013   │ 1      │ 1      │ 1952     │ 1930           │ 22        │\n│ 7      │ 2013   │ 1      │ 1      │ 2016     │ 1930           │ 46        │\n⋮\n│ 336769 │ 2013   │ 5      │ 7      │ 2054     │ 2055           │ -1        │\n│ 336770 │ 2013   │ 5      │ 13     │ 657      │ 700            │ -3        │\n│ 336771 │ 2013   │ 5      │ 2      │ 1926     │ 1929           │ -3        │\n│ 336772 │ 2013   │ 5      │ 4      │ 1816     │ 1820           │ -4        │\n│ 336773 │ 2013   │ 5      │ 2      │ 1947     │ 1949           │ -2        │\n│ 336774 │ 2013   │ 5      │ 6      │ 1826     │ 1830           │ -4        │\n│ 336775 │ 2013   │ 5      │ 20     │ 719      │ 735            │ -16       │\n│ 336776 │ 2013   │ 5      │ 7      │ 1715     │ 1729           │ -14       │In the original column-wise form, you can select or remove columns.julia> @> flights |>\n          select(_, :year, :month, :day) |>\n          pretty\n336776×3 DataFrames.DataFrame\n│ Row    │ year   │ month  │ day    │\n│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │\n├────────┼────────┼────────┼────────┤\n│ 1      │ 2013   │ 1      │ 1      │\n│ 2      │ 2013   │ 1      │ 1      │\n│ 3      │ 2013   │ 1      │ 1      │\n│ 4      │ 2013   │ 1      │ 1      │\n│ 5      │ 2013   │ 1      │ 1      │\n│ 6      │ 2013   │ 1      │ 1      │\n│ 7      │ 2013   │ 1      │ 1      │\n⋮\n│ 336769 │ 2013   │ 9      │ 30     │\n│ 336770 │ 2013   │ 9      │ 30     │\n│ 336771 │ 2013   │ 9      │ 30     │\n│ 336772 │ 2013   │ 9      │ 30     │\n│ 336773 │ 2013   │ 9      │ 30     │\n│ 336774 │ 2013   │ 9      │ 30     │\n│ 336775 │ 2013   │ 9      │ 30     │\n│ 336776 │ 2013   │ 9      │ 30     │\n\njulia> @> flights |>\n          remove(_, :year, :month, :day) |>\n          pretty\n336776×16 DataFrames.DataFrame. Omitted printing of 11 columns\n│ Row    │ dep_time │ sched_dep_time │ dep_delay │ arr_time │ sched_arr_time │\n│        │ Int64⍰   │ Int64⍰         │ Int64⍰    │ Int64⍰   │ Int64⍰         │\n├────────┼──────────┼────────────────┼───────────┼──────────┼────────────────┤\n│ 1      │ 517      │ 515            │ 2         │ 830      │ 819            │\n│ 2      │ 533      │ 529            │ 4         │ 850      │ 830            │\n│ 3      │ 542      │ 540            │ 2         │ 923      │ 850            │\n│ 4      │ 544      │ 545            │ -1        │ 1004     │ 1022           │\n│ 5      │ 554      │ 600            │ -6        │ 812      │ 837            │\n│ 6      │ 554      │ 558            │ -4        │ 740      │ 728            │\n│ 7      │ 555      │ 600            │ -5        │ 913      │ 854            │\n⋮\n│ 336769 │ 2307     │ 2255           │ 12        │ 2359     │ 2358           │\n│ 336770 │ 2349     │ 2359           │ -10       │ 325      │ 350            │\n│ 336771 │ missing  │ 1842           │ missing   │ missing  │ 2019           │\n│ 336772 │ missing  │ 1455           │ missing   │ missing  │ 1634           │\n│ 336773 │ missing  │ 2200           │ missing   │ missing  │ 2312           │\n│ 336774 │ missing  │ 1210           │ missing   │ missing  │ 1330           │\n│ 336775 │ missing  │ 1159           │ missing   │ missing  │ 1344           │\n│ 336776 │ missing  │ 840            │ missing   │ missing  │ 1020           │You can also rename columns. Because constants (currently) do not propagate through keyword arguments in Julia, it\'s smart to wrap column names with Name.julia> @> flights |>\n          rename(_, tail_num = Name(:tailnum)) |>\n          pretty\n336776×19 DataFrames.DataFrame. Omitted printing of 13 columns\n│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │\n│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │\n├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤\n│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │\n│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │\n│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │\n│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │\n│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │\n│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │\n│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │\n⋮\n│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │\n│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │\n│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │\n│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │\n│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │\n│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │\n│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │\n│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │You can add new columns with transform. If you want to refer to previous columns, you\'ll have to transform twice.julia> @> flights |>\n          transform(_,\n                    gain = _.arr_delay .- _.dep_delay,\n                    speed = _.distance ./ _.air_time .* 60\n          ) |>\n          transform(_,\n                    gain_per_hour = _.gain ./ (_.air_time / 60)\n          ) |>\n          pretty\n336776×22 DataFrames.DataFrame. Omitted printing of 16 columns\n│ Row    │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │\n│        │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │\n├────────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤\n│ 1      │ 2013   │ 1      │ 1      │ 517      │ 515            │ 2         │\n│ 2      │ 2013   │ 1      │ 1      │ 533      │ 529            │ 4         │\n│ 3      │ 2013   │ 1      │ 1      │ 542      │ 540            │ 2         │\n│ 4      │ 2013   │ 1      │ 1      │ 544      │ 545            │ -1        │\n│ 5      │ 2013   │ 1      │ 1      │ 554      │ 600            │ -6        │\n│ 6      │ 2013   │ 1      │ 1      │ 554      │ 558            │ -4        │\n│ 7      │ 2013   │ 1      │ 1      │ 555      │ 600            │ -5        │\n⋮\n│ 336769 │ 2013   │ 9      │ 30     │ 2307     │ 2255           │ 12        │\n│ 336770 │ 2013   │ 9      │ 30     │ 2349     │ 2359           │ -10       │\n│ 336771 │ 2013   │ 9      │ 30     │ missing  │ 1842           │ missing   │\n│ 336772 │ 2013   │ 9      │ 30     │ missing  │ 1455           │ missing   │\n│ 336773 │ 2013   │ 9      │ 30     │ missing  │ 2200           │ missing   │\n│ 336774 │ 2013   │ 9      │ 30     │ missing  │ 1210           │ missing   │\n│ 336775 │ 2013   │ 9      │ 30     │ missing  │ 1159           │ missing   │\n│ 336776 │ 2013   │ 9      │ 30     │ missing  │ 840            │ missing   │No summarize here, but you can just directly access columns:julia> using Statistics: mean;\n\njulia> mean(skipmissing(flights.dep_delay))\n12.639070257304708I don\'t provide a export a sample function here, but StatsBase does.Grouping here works differently than in dplyr:You can only order sorted data. To let Julia know that the data has been sorted, you need to explicitly wrap the data with By.\nSecond, groups return a pair, key => sub-data-frame. So:julia> by_tailnum =\n          @> flights |>\n          rows |>\n          order(_, select(:tailnum)) |>\n          By(_, select(:tailnum)) |>\n          Group;\n\njulia> pair = first(by_tailnum);\n\njulia> pair.first\n(tailnum = \"D942DN\",)\n\njulia> @> pair.second |>\n          autocolumns |>\n          pretty\n4×19 DataFrames.DataFrame. Omitted printing of 13 columns\n│ Row │ year   │ month  │ day    │ dep_time │ sched_dep_time │ dep_delay │\n│     │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰   │ Int64⍰         │ Int64⍰    │\n├─────┼────────┼────────┼────────┼──────────┼────────────────┼───────────┤\n│ 1   │ 2013   │ 2      │ 11     │ 1508     │ 1400           │ 68        │\n│ 2   │ 2013   │ 3      │ 23     │ 1340     │ 1300           │ 40        │\n│ 3   │ 2013   │ 3      │ 24     │ 859      │ 835            │ 24        │\n│ 4   │ 2013   │ 7      │ 5      │ 1253     │ 1259           │ -6        │Third, you have to explicity use over to map over groups.So putting it all together, here is the example from the dplyr docs, LightQuery style. This is the first time in this example where autocolumns won\'t work. You\'ll have to explicitly use columns for the last call.julia> @> by_tailnum |>\n          over(_, @_ begin\n                    sub_frame = autocolumns(_.second)\n                    transform(_.first,\n                              count = length(_.second),\n                              distance = sub_frame.distance |> skipmissing |> mean,\n                              delay = sub_frame.arr_delay |> skipmissing |> mean\n                    )\n          end) |>\n          columns(_, :tailnum, :count, :distance, :delay) |>\n          pretty\n4044×4 DataFrames.DataFrame\n│ Row  │ tailnum │ count │ distance │ delay    │\n│      │ String⍰ │ Int64 │ Float64  │ Float64  │\n├──────┼─────────┼───────┼──────────┼──────────┤\n│ 1    │ D942DN  │ 4     │ 854.5    │ 31.5     │\n│ 2    │ N0EGMQ  │ 371   │ 676.189  │ 9.98295  │\n│ 3    │ N10156  │ 153   │ 757.948  │ 12.7172  │\n│ 4    │ N102UW  │ 48    │ 535.875  │ 2.9375   │\n│ 5    │ N103US  │ 46    │ 535.196  │ -6.93478 │\n│ 6    │ N104UW  │ 47    │ 535.255  │ 1.80435  │\n│ 7    │ N10575  │ 289   │ 519.702  │ 20.6914  │\n⋮\n│ 4037 │ N996DL  │ 102   │ 897.304  │ 0.524752 │\n│ 4038 │ N997AT  │ 44    │ 679.045  │ 16.3023  │\n│ 4039 │ N997DL  │ 63    │ 867.762  │ 4.90323  │\n│ 4040 │ N998AT  │ 26    │ 593.538  │ 29.96    │\n│ 4041 │ N998DL  │ 77    │ 857.818  │ 16.3947  │\n│ 4042 │ N999DN  │ 61    │ 895.459  │ 14.3115  │\n│ 4043 │ N9EAMQ  │ 248   │ 674.665  │ 9.23529  │\n│ 4044 │ missing │ 2512  │ 710.258  │ NaN      │For the n-distinct example, I\'ve switched things around to be just a smidge more efficient. This example shows how calling columns then rows is sometimes necessary to trigger eager evaluation.julia> dest_tailnum =\n          @> flights |>\n          rows |>\n          order(_, select(:dest, :tailnum)) |>\n          By(_, select(:dest, :tailnum)) |>\n          Group |>\n          over(_, @_ transform(_.first,\n                    flights = length(_.second)\n          )) |>\n          columns(_, :dest, :tailnum, :flights) |>\n          rows |>\n          By(_, select(:dest)) |>\n          Group |>\n          over(_, @_ transform(_.first,\n                    flights = sum(autocolumns(_.second).flights),\n                    planes = length(_.second)\n          )) |>\n          columns(_, :flights, :planes) |>\n          pretty\n105×2 DataFrames.DataFrame\n│ Row │ flights │ planes │\n│     │ Int64   │ Int64  │\n├─────┼─────────┼────────┤\n│ 1   │ 254     │ 108    │\n│ 2   │ 265     │ 58     │\n│ 3   │ 439     │ 172    │\n│ 4   │ 8       │ 6      │\n│ 5   │ 17215   │ 1180   │\n│ 6   │ 2439    │ 993    │\n│ 7   │ 275     │ 159    │\n⋮\n│ 98  │ 4339    │ 960    │\n│ 99  │ 522     │ 87     │\n│ 100 │ 1761    │ 383    │\n│ 101 │ 7466    │ 1126   │\n│ 102 │ 315     │ 105    │\n│ 103 │ 101     │ 60     │\n│ 104 │ 631     │ 273    │\n│ 105 │ 1036    │ 176    │As I mentioned before, you can use By without order if you know a dataset has been pre-sorted. This makes rolling up data-sets fairly easy.julia> per_day =\n          @> by_date |>\n          By(_, select(:year, :month, :day)) |>\n          Group |>\n          over(_, @_ transform(_.first, flights = length(_.second))) |>\n          columns(_, :year, :month, :day, :flights);\n\njulia> pretty(per_day)\n365×4 DataFrames.DataFrame\n│ Row │ year  │ month │ day   │ flights │\n│     │ Int64 │ Int64 │ Int64 │ Int64   │\n├─────┼───────┼───────┼───────┼─────────┤\n│ 1   │ 2013  │ 1     │ 1     │ 842     │\n│ 2   │ 2013  │ 1     │ 2     │ 943     │\n│ 3   │ 2013  │ 1     │ 3     │ 914     │\n│ 4   │ 2013  │ 1     │ 4     │ 915     │\n│ 5   │ 2013  │ 1     │ 5     │ 720     │\n│ 6   │ 2013  │ 1     │ 6     │ 832     │\n│ 7   │ 2013  │ 1     │ 7     │ 933     │\n⋮\n│ 358 │ 2013  │ 12    │ 24    │ 761     │\n│ 359 │ 2013  │ 12    │ 25    │ 719     │\n│ 360 │ 2013  │ 12    │ 26    │ 936     │\n│ 361 │ 2013  │ 12    │ 27    │ 963     │\n│ 362 │ 2013  │ 12    │ 28    │ 814     │\n│ 363 │ 2013  │ 12    │ 29    │ 888     │\n│ 364 │ 2013  │ 12    │ 30    │ 968     │\n│ 365 │ 2013  │ 12    │ 31    │ 776     │\n\njulia> per_month =\n          @> per_day|>\n          rows |>\n          By(_, select(:year, :month)) |>\n          Group |>\n          over(_, @_ transform(_.first,\n                    flights = sum(autocolumns(_.second).flights))) |>\n          columns(_, :year, :month, :flights);\n\njulia> pretty(per_month)\n12×3 DataFrames.DataFrame\n│ Row │ year  │ month │ flights │\n│     │ Int64 │ Int64 │ Int64   │\n├─────┼───────┼───────┼─────────┤\n│ 1   │ 2013  │ 1     │ 27004   │\n│ 2   │ 2013  │ 2     │ 24951   │\n│ 3   │ 2013  │ 3     │ 28834   │\n│ 4   │ 2013  │ 4     │ 28330   │\n│ 5   │ 2013  │ 5     │ 28796   │\n│ 6   │ 2013  │ 6     │ 28243   │\n│ 7   │ 2013  │ 7     │ 29425   │\n│ 8   │ 2013  │ 8     │ 29327   │\n│ 9   │ 2013  │ 9     │ 27574   │\n│ 10  │ 2013  │ 10    │ 28889   │\n│ 11  │ 2013  │ 11    │ 27268   │\n│ 12  │ 2013  │ 12    │ 28135   │\n\njulia> per_year =\n          @> per_month |>\n          rows |>\n          By(_, select(:year)) |>\n          Group |>\n          over(_, @_ transform(_.first,\n                    flights = sum(autocolumns(_.second).flights))) |>\n          columns(_, :year, :flights);\n\njulia> pretty(per_year)\n1×2 DataFrames.DataFrame\n│ Row │ year  │ flights │\n│     │ Int64 │ Int64   │\n├─────┼───────┼─────────┤\n│ 1   │ 2013  │ 336776  │Here\'s the example in the dplyr docs for piping:julia> @> by_date |>\n          By(_, select(:year, :month, :day)) |>\n          Group |>\n          over(_, @_ begin\n                    sub_frame = autocolumns(_.second)\n                    transform(_.first,\n                              arr = sub_frame.arr_delay |> skipmissing |> mean,\n                              dep = sub_frame.dep_delay |> skipmissing |> mean\n                    )\n          end) |>\n          when(_, @_ _.arr > 30 || _.dep > 30) |>\n          columns(_, :year, :month, :day, :arr, :dep) |>\n          pretty\n49×5 DataFrames.DataFrame\n│ Row │ year  │ month │ day   │ arr     │ dep     │\n│     │ Int64 │ Int64 │ Int64 │ Float64 │ Float64 │\n├─────┼───────┼───────┼───────┼─────────┼─────────┤\n│ 1   │ 2013  │ 1     │ 16    │ 34.2474 │ 24.6129 │\n│ 2   │ 2013  │ 1     │ 31    │ 32.6029 │ 28.6584 │\n│ 3   │ 2013  │ 2     │ 11    │ 36.2901 │ 39.0736 │\n│ 4   │ 2013  │ 2     │ 27    │ 31.2525 │ 37.7633 │\n│ 5   │ 2013  │ 3     │ 8     │ 85.8622 │ 83.5369 │\n│ 6   │ 2013  │ 3     │ 18    │ 41.2919 │ 30.118  │\n│ 7   │ 2013  │ 4     │ 10    │ 38.4123 │ 33.0237 │\n⋮\n│ 42  │ 2013  │ 10    │ 11    │ 18.923  │ 31.2318 │\n│ 43  │ 2013  │ 12    │ 5     │ 51.6663 │ 52.328  │\n│ 44  │ 2013  │ 12    │ 8     │ 36.9118 │ 21.5153 │\n│ 45  │ 2013  │ 12    │ 9     │ 42.5756 │ 34.8002 │\n│ 46  │ 2013  │ 12    │ 10    │ 44.5088 │ 26.4655 │\n│ 47  │ 2013  │ 12    │ 14    │ 46.3975 │ 28.3616 │\n│ 48  │ 2013  │ 12    │ 17    │ 55.8719 │ 40.7056 │\n│ 49  │ 2013  │ 12    │ 23    │ 32.226  │ 32.2541 │Again, for inference reasons, natural joins won\'t work. I only provide one join at the moment, but it\'s super efficient. Let\'s start by reading in airlines and letting julia konw that it\'s already sorted by :carrier.julia> airlines =\n          @> CSV.read(\"airlines.csv\", missingstring = \"NA\") |>\n          named_tuple |>\n          remove(_, Symbol(\"\")) |>\n          rows |>\n          By(_, select(:carrier));If we want to join this data into the flights data, here\'s what we do. LeftJoin requires not only presorted but unique keys. Of course, there are multiple flights from the same airline, so we need to group first. Then, we tell Julia that the groups are themselves sorted (by the first item, the key). Finally we can join in the airline data. But the results are a bit tricky. Let\'s take a look at the first item. Just like the dplyr manual, I\'m only using a few of the columns from flights for demonstration.julia> sample_join =\n          @> flights |>\n          select(_, :year, :month, :day, :hour, :origin, :dest, :tailnum, :carrier) |>\n          rows |>\n          order(_, select(:carrier)) |>\n          By(_, select(:carrier)) |>\n          Group |>\n          By(_, first) |>\n          LeftJoin(_, airlines);\n\njulia> first_join = first(sample_join);We end up getting a group on the left, and a row on the right.julia> first_join.first.first\n(carrier = \"9E\",)\n\njulia> @> first_join.first.second |>\n            autocolumns |>\n            pretty\n18460×8 DataFrames.DataFrame. Omitted printing of 1 columns\n│ Row   │ year   │ month  │ day    │ hour   │ origin  │ dest    │ tailnum │\n│       │ Int64⍰ │ Int64⍰ │ Int64⍰ │ Int64⍰ │ String⍰ │ String⍰ │ String⍰ │\n├───────┼────────┼────────┼────────┼────────┼─────────┼─────────┼─────────┤\n│ 1     │ 2013   │ 1      │ 1      │ 8      │ JFK     │ MSP     │ N915XJ  │\n│ 2     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ IAD     │ N8444F  │\n│ 3     │ 2013   │ 1      │ 1      │ 14     │ JFK     │ BUF     │ N920XJ  │\n│ 4     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ SYR     │ N8409N  │\n│ 5     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ ROC     │ N8631E  │\n│ 6     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ BWI     │ N913XJ  │\n│ 7     │ 2013   │ 1      │ 1      │ 15     │ JFK     │ ORD     │ N904XJ  │\n⋮\n│ 18453 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ IAD     │ N8790A  │\n│ 18454 │ 2013   │ 9      │ 30     │ 20     │ LGA     │ TYS     │ N8924B  │\n│ 18455 │ 2013   │ 9      │ 30     │ 19     │ JFK     │ PHL     │ N602XJ  │\n│ 18456 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ DCA     │ N602LR  │\n│ 18457 │ 2013   │ 9      │ 30     │ 20     │ JFK     │ BWI     │ N8423C  │\n│ 18458 │ 2013   │ 9      │ 30     │ 18     │ JFK     │ BUF     │ N906XJ  │\n│ 18459 │ 2013   │ 9      │ 30     │ 14     │ JFK     │ DCA     │ missing │\n│ 18460 │ 2013   │ 9      │ 30     │ 22     │ LGA     │ SYR     │ missing │\n\njulia> first_join.second\n(carrier = \"9E\", name = \"Endeavor Air Inc.\")If you want to collect your results into a flat new dataframe, you need to do a bit of surgery, including making use of Iterators.flatten:julia> @> sample_join |>\n          over(_, @_ begin\n                    left_rows = _.first.second\n                    right_row = _.second\n                    over(left_rows, @_ transform(_,\n                              airline_name = right_row.name))\n          end) |>\n          Iterators.flatten(_) |>\n          columns(_, :year, :month, :day, :hour, :origin, :dest, :tailnum,\n                    :carrier, :airline_name) |>\n          pretty\n336776×9 DataFrames.DataFrame. Omitted printing of 1 columns\n│ Row    │ year  │ month │ day   │ hour  │ origin │ dest   │ tailnum │ carrier │\n│        │ Int64 │ Int64 │ Int64 │ Int64 │ String │ String │ String⍰ │ String  │\n├────────┼───────┼───────┼───────┼───────┼────────┼────────┼─────────┼─────────┤\n│ 1      │ 2013  │ 1     │ 1     │ 8     │ JFK    │ MSP    │ N915XJ  │ 9E      │\n│ 2      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ IAD    │ N8444F  │ 9E      │\n│ 3      │ 2013  │ 1     │ 1     │ 14    │ JFK    │ BUF    │ N920XJ  │ 9E      │\n│ 4      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ SYR    │ N8409N  │ 9E      │\n│ 5      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ ROC    │ N8631E  │ 9E      │\n│ 6      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ BWI    │ N913XJ  │ 9E      │\n│ 7      │ 2013  │ 1     │ 1     │ 15    │ JFK    │ ORD    │ N904XJ  │ 9E      │\n⋮\n│ 336769 │ 2013  │ 9     │ 27    │ 16    │ LGA    │ IAD    │ N514MJ  │ YV      │\n│ 336770 │ 2013  │ 9     │ 27    │ 17    │ LGA    │ CLT    │ N925FJ  │ YV      │\n│ 336771 │ 2013  │ 9     │ 28    │ 19    │ LGA    │ IAD    │ N501MJ  │ YV      │\n│ 336772 │ 2013  │ 9     │ 29    │ 16    │ LGA    │ IAD    │ N518LR  │ YV      │\n│ 336773 │ 2013  │ 9     │ 29    │ 17    │ LGA    │ CLT    │ N932LR  │ YV      │\n│ 336774 │ 2013  │ 9     │ 30    │ 16    │ LGA    │ IAD    │ N510MJ  │ YV      │\n│ 336775 │ 2013  │ 9     │ 30    │ 17    │ LGA    │ CLT    │ N905FJ  │ YV      │\n│ 336776 │ 2013  │ 9     │ 30    │ 20    │ LGA    │ CLT    │ N924FJ  │ YV      │"
},

]}
