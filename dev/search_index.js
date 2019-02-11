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
    "text": "By(it, call)\n\nMarks that it has been pre-sorted by the key call. For use with Group or FullJoin.\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.FullJoin",
    "page": "LightQuery.jl",
    "title": "LightQuery.FullJoin",
    "category": "type",
    "text": "FullJoin(left::By, right::By)\n\nFind all pairs where isequal(left.call(left.it), right.call(right.it)). Assumes left and right are both strictly sorted (no repeats). If there are repeats, Group first. For other join flavors, combine with Filter.\n\njulia> using LightQuery\n\njulia> FullJoin(\n            By([1, 2, 5, 6], identity),\n            By([1, 3, 4, 6], identity)\n        ) |>\n        collect\n6-element Array{Pair{Union{Missing, Int64},Union{Missing, Int64}},1}:\n       1 => 1\n       2 => missing\n missing => 3\n missing => 4\n       5 => missing\n       6 => 6\n\njulia> @> [1, 1, 2, 2] |>\n        Group(By(_, identity)) |>\n        By(_, first) |>\n        FullJoin(_, By([1, 2], identity)) |>\n        collect\n2-element Array{Pair{Pair{Int64,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},Int64},1}:\n (1=>[1, 1]) => 1\n (2=>[2, 2]) => 2\n\njulia> @> FullJoin(\n            By([1, 2, 5, 6], identity),\n            By([1, 3, 4, 6], identity)\n        ) |>\n        Filter((@_ !ismissing(_.first)), _) |>\n        collect\n4-element Array{Pair{Union{Missing, Int64},Union{Missing, Int64}},1}:\n 1 => 1\n 2 => missing\n 5 => missing\n 6 => 6\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Group-Tuple{LightQuery.By}",
    "page": "LightQuery.jl",
    "title": "LightQuery.Group",
    "category": "method",
    "text": "Group(it::By)\n\nGroup consecutive keys in it. Requires a presorted object (see By). Relies on the fact that iteration states can be converted to indices; thus, you might have to define LightQuery.state_to_index for unrecognized types.\n\njulia> using LightQuery\n\njulia> Group(By([1, 3, 2, 4], iseven)) |> collect\n2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:\n 0 => [1, 3]\n 1 => [2, 4]\n\n\n\n\n\n"
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
    "text": "Name(name)\n\nForce into the type domain. Can also be used as a function to getproperty\n\njulia> using LightQuery\n\njulia> @> (a = 1,) |>\n        Name(:a)(_)\n1\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Names-Tuple",
    "page": "LightQuery.jl",
    "title": "LightQuery.Names",
    "category": "method",
    "text": "Names(the_names...)\n\nForce into the type domain. Can be used to as a function to select columns.\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0) |>\n        Names(:a)(_)\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Peek-Union{Tuple{It}, Tuple{It}} where It",
    "page": "LightQuery.jl",
    "title": "LightQuery.Peek",
    "category": "method",
    "text": "Peek(it; max_columns = 7, max_rows = 4)\n\nGet a peek of an iterator which returns named tuples. If inference cannot detect names, it will use the names of the first item.\n\njulia> using LightQuery\n\njulia> [(a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8)] |>\n        Peek\nShowing 7 of 8 columns\n|  :a |  :b |  :c |  :d |  :e |  :f |  :g |\n| ---:| ---:| ---:| ---:| ---:| ---:| ---:|\n|   1 |   2 |   3 |   4 |   5 |   6 |   7 |\n\njulia> (a = 1:6,) |>\n        rows |>\n        Peek\nShowing 4 of 6 rows\n|  :a |\n| ---:|\n|   1 |\n|   2 |\n|   3 |\n|   4 |\n\njulia> @> (a = 1:2,) |>\n        rows |>\n        Filter((@_ _.a > 1), _) |>\n        Peek\nShowing at most 4 rows\n|  :a |\n| ---:|\n|   2 |\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.columns-Union{Tuple{Base.Generator{It,LightQuery.Names{names}}}, Tuple{names}, Tuple{It}} where names where It<:LightQuery.ZippedArrays",
    "page": "LightQuery.jl",
    "title": "LightQuery.columns",
    "category": "method",
    "text": "columns(it)\n\nInverse of rows.\n\njulia> using LightQuery\n\njulia> (a = [1], b = [1.0]) |>\n        rows |>\n        columns\n(a = [1], b = [1.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.gather",
    "category": "method",
    "text": "gather(it; assignments...)\n\nFor each key => value pair in assignments, gather the Names in value into a single key. Inverse of spread.\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0, c = 1//1) |>\n        gather(_, d = Names(:a, :c))\n(b = 1.0, d = (a = 1, c = 1//1))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.in_common-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.in_common",
    "category": "method",
    "text": "in_common(it1, it2)\n\nFind the the_names in common between it1 and it2.\n\njulia> using LightQuery\n\njulia> in_common((a = 1, b = 1.0), (a = 2, c = 2//2))\n(:a,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.make_columns-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.make_columns",
    "category": "method",
    "text": "make_columns(it)\n\nCollect into columns. See also columns. If inference cannot detect names, it will use the names of the first item. Much more efficient if it has a known length/size.\n\njulia> using LightQuery\n\njulia> [(a = 1, b = 1.0), (a = 2, b = 2.0)] |>\n        make_columns\n(a = [1, 2], b = [1.0, 2.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.named_tuple-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.named_tuple",
    "category": "method",
    "text": "named_tuple(it)\n\nCoerce to a named_tuple. For performance with working with arbitrary structs, requires propertynames to constant propagate.\n\njulia> using LightQuery\n\njulia> @inline Base.propertynames(p::Pair) = (:first, :second);\n\njulia> named_tuple(:a => 1)\n(first = :a, second = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.order-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.order",
    "category": "method",
    "text": "order(it, call; keywords...)\norder(it, call, condition; keywords...)\n\nGeneralized sort. keywords will be passed to sort!; see the documentation there for options. See By for a way to explicitly mark that an object has been sorted. Most performant if call is type stable, if not, consider using a condition to filter.\n\njulia> using LightQuery\n\njulia> order([2, 1], identity)\n2-element view(::Array{Int64,1}, [2, 1]) with eltype Int64:\n 1\n 2\n\njulia> order([1, 2, missing], identity, !ismissing)\n2-element view(::Array{Union{Missing, Int64},1}, [1, 2]) with eltype Union{Missing, Int64}:\n 1\n 2\n\n\n\n\n\n"
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
    "text": "rename(it; renames::Name...)\n\nRename it. Use Name for type stability; constants don\'t propagate through keyword arguments :(\n\njulia> using LightQuery\n\njulia> @> (a = 1, b = 1.0) |>\n        rename(_, c = Name(:a))\n(b = 1.0, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.row_type-Tuple{CSV.File}",
    "page": "LightQuery.jl",
    "title": "LightQuery.row_type",
    "category": "method",
    "text": "row_type(f::File)\n\nFind the type of a row of a CSV.File if it was converted to a named_tuple.\n\n``` julia> using LightQuery\n\njulia> @> \"test.csv\" |>         CSV.File(, allowmissing = :auto) |>         rowtype NamedTuple{(:a, :b),T} where T<:Tuple{Int64,Float64}\n\n\n\n\n\n"
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
    "text": "transform(it; assignments...)\n\nMerge assignments into it.\n\njulia> using LightQuery\n\njulia> transform((a = 1,), b = 1.0)\n(a = 1, b = 1.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.unzip-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.unzip",
    "category": "method",
    "text": "unzip(it, n)\n\nUnzip an iterator it which returns tuples of length n.\n\njulia> using LightQuery\n\njulia> unzip([(1, 1.0), (2, 2.0)], 2)\n([1, 2], [1.0, 2.0])\n\n\n\n\n\n"
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

]}
