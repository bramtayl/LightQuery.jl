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
    "text": "group(b::By)\n\nGroup consecutive keys in b. Requires a presorted object (see By).\n\njulia> using LightQuery\n\njulia> Group(By([1, 3, 2, 4], iseven)) |> collect\n2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:\n 0 => [1, 3]\n 1 => [2, 4]\n\n\n\n\n\n"
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
    "text": "Name(x)\n\nForce into the type domain.\n\njulia> using LightQuery\n\njulia> Name(:a)\nName{:a}()\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.columns-Tuple{Any,Vararg{Any,N} where N}",
    "page": "LightQuery.jl",
    "title": "LightQuery.columns",
    "category": "method",
    "text": "columns(it, names...)\n\nCollect into columns. Inverse of rows.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = columns(x, :a, :b);\n\njulia> @inferred test([(a = 1, b = 1.0)])\n(a = [1], b = [1.0])\n\n\n\n\n\n"
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
    "text": "named_tuple(x)\n\nCoerce to a named_tuple.\n\njulia> using LightQuery\n\njulia> named_tuple(:a => 1)\n(first = :a, second = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.order_by-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.order_by",
    "category": "method",
    "text": "order_by(it, f)\n\nGeneralized sort. Will return a By object.\n\njulia> using LightQuery\n\njulia> order_by([\"b\", \"a\"], identity).it\n2-element view(::Array{String,1}, [2, 1]) with eltype String:\n \"a\"\n \"b\"\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.over-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.over",
    "category": "method",
    "text": "over(it, f)\n\nHackable reversed version of Base.Generator.\n\njulia> using LightQuery\n\njulia> over([1, 2], x -> x + 1) |> collect\n2-element Array{Int64,1}:\n 2\n 3\n\n\n\n\n\n"
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
    "text": "rename(data; renames...)\n\nRename data. Currently unstable.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> test(x) = rename(x, c = :a);\n\njulia> test((a = 1, b = 2.0))\n(b = 2.0, c = 1)\n\n\n\n\n\n"
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
    "text": "transform(data; assignments...)\n\nApply the functions in assignments to data, assign to the corresponding keys, and merge back in the original.\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred transform((a = 1, b = 2.0), c = @_ _.a + _.b)\n(a = 1, b = 2.0, c = 3.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.unzip-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.unzip",
    "category": "method",
    "text": "unzip(it, n)\n\nUnzip an iterator it which returns tuples of length n.\n\njulia> using LightQuery\n\njulia> f(x) = (x, x + 1.0);\n\njulia> unzip(over([1], f), 2)\n([1], [2.0])\n\njulia> unzip(over([1, missing], f), 2);\n\njulia> unzip(zip([1], [1.0]), 2)\n([1], [1.0])\n\njulia> unzip([(1, 1.0)], 2)\n([1], [1.0])\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.when-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.when",
    "category": "method",
    "text": "when(it, f)\n\nHackable reversed version of Base.Iterators.Filter.\n\njulia> using LightQuery\n\njulia> when([1, 2], x -> x > 1) |> collect\n1-element Array{Int64,1}:\n 2\n\n\n\n\n\n"
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
    "text": "For performance with working with arbitrary structs, explicitly define public propertynames.Modules = [LightQuery]"
},

]}
