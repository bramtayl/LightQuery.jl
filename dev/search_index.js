var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "LightQuery.jl",
    "title": "LightQuery.jl",
    "category": "page",
    "text": ""
},

{
    "location": "#LightQuery.LeftJoin",
    "page": "LightQuery.jl",
    "title": "LightQuery.LeftJoin",
    "category": "type",
    "text": "LeftJoin(left_key, right_key, left, right)\nLeftJoin(left_key, [right_key = left_key], left, right)\n\nReturn each value in left, and, if it exists, the item in right where isequal(left_key(left), right_key(right)), assuming both are strictly sorted by the respective keys.\n\njulia> using LightQuery\n\njulia> LeftJoin(identity, [1, 2, 5, 6], [1, 3, 4, 6]) |> collect\n4-element Array{Tuple{Int64,Union{Missing, Int64}},1}:\n (1, 1)\n (2, missing)\n (5, missing)\n (6, 6)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Name",
    "page": "LightQuery.jl",
    "title": "LightQuery.Name",
    "category": "type",
    "text": "struct Name{T} end\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred Name(:a)((a = 1, b = 2.0,))\n1\n\njulia> @inferred merge(Name(:a), Name(:b))\nNames{(:a, :b)}()\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Nameless",
    "page": "LightQuery.jl",
    "title": "LightQuery.Nameless",
    "category": "type",
    "text": "A container for a function and the expression that generated it\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Names",
    "page": "LightQuery.jl",
    "title": "LightQuery.Names",
    "category": "type",
    "text": "struct Names{T} end\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred Names(:a)((a = 1, b = 2.0,))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.based_on-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.based_on",
    "category": "method",
    "text": "based_on(data; assignments...)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred based_on((a = 1, b = 2.0), c = @_ _.a + _.b)\n(c = 3.0,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.chunk_by-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.chunk_by",
    "category": "method",
    "text": "chunk_by(f, x)\n\nGroup x by consecutive results of f.\n\njulia> using LightQuery\n\njulia> chunk_by(iseven, [1, 3, 2, 4]) |> collect\n2-element Array{Pair{Bool,SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64}},true}},1}:\n false => [1, 3]\n  true => [2, 4]\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather-Tuple{Any,LightQuery.Names,LightQuery.Name}",
    "page": "LightQuery.jl",
    "title": "LightQuery.gather",
    "category": "method",
    "text": "gather(data, columns::Names, new_column::Name)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred gather((a = 1, b = 2.0, c = \"c\"), Names(:a, :c), Name(:d))\n(b = 2.0, d = (a = 1, c = \"c\"))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.in_common-Tuple{Any,Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.in_common",
    "category": "method",
    "text": "in_common(data1, data2)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred in_common((a = 1, b = 2.0), (a = 1, c = \"3\"))\nNames{(:a,)}()\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.invert-Tuple{NamedTuple}",
    "page": "LightQuery.jl",
    "title": "LightQuery.invert",
    "category": "method",
    "text": "invert(n::NamedTuple)\n\njulia> using LightQuery\n\njulia> invert((a = [1, 2], b = [2, 1])) |> collect\n2-element Array{NamedTuple{(:a, :b),Tuple{Int64,Int64}},1}:\n (a = 1, b = 2)\n (a = 2, b = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.name-Union{Tuple{T}, Tuple{Any,Names{T}}} where T",
    "page": "LightQuery.jl",
    "title": "LightQuery.name",
    "category": "method",
    "text": "name(data, names::Names)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred name((a = 1, b = 2.0), Names(:c, :d))\n(c = 1, d = 2.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.named-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.named",
    "category": "method",
    "text": "named(data)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred named((a = 1, b = 2.0))\n(a = 1, b = 2.0)\n\njulia> struct Triple{T1, T2, T3}\n            first::T1\n            second::T2\n            third::T3\n        end;\n\njulia> Base.propertynames(t::Triple) = (:first, :second, :third);\n\njulia> @inferred named(Triple(1, 1.0, \"a\"))\n(first = 1, second = 1.0, third = \"a\")\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.remove-Union{Tuple{T}, Tuple{Any,Names{T}}} where T",
    "page": "LightQuery.jl",
    "title": "LightQuery.remove",
    "category": "method",
    "text": "remove(data, columns::Names)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred remove((a = 1, b = 2.0), Names(:b))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rename-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.rename",
    "category": "method",
    "text": "rename(data; renames...)\n\njulia> using LightQuery\n\njulia> rename((a = 1, b = 2.0), c = Name(:a))\n(b = 2.0, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.select-Union{Tuple{T}, Tuple{Any,Names{T}}} where T",
    "page": "LightQuery.jl",
    "title": "LightQuery.select",
    "category": "method",
    "text": "select(data, columns::Names)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred select((a = 1, b = 2.0), Names(:a))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.spread-Tuple{Any,LightQuery.Name}",
    "page": "LightQuery.jl",
    "title": "LightQuery.spread",
    "category": "method",
    "text": "spread(data, column::Name)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred spread((b = 2.0, d = (a = 1, c = \"c\")), Name(:d))\n(b = 2.0, a = 1, c = \"c\")\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.transform-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.transform",
    "category": "method",
    "text": "transform(data; assignments...)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred transform((a = 1, b = 2.0), c = @_ _.a + _.b)\n(a = 1, b = 2.0, c = 3.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.unname-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.unname",
    "category": "method",
    "text": "unname\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred unname((a = 1, b = 2.0))\n(1, 2.0)\n\njulia> @inferred unname((1, 2.0))\n(1, 2.0)\n\njulia> struct Triple{T1, T2, T3}\n            first::T1\n            second::T2\n            third::T3\n        end;\n\njulia> Base.propertynames(t::Triple) = (:first, :second, :third);\n\njulia> @inferred unname(Triple(1, 1.0, \"a\"))\n(1, 1.0, \"a\")\n\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@>-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.@>",
    "category": "macro",
    "text": "macro >(body)\n\nIf body is in the form body_ |> tail_, call @_ on tail, and recur on body.\n\njulia> using LightQuery\n\njulia> @> 0 |> _ + 1 |> _ - 1\n0\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@_-Tuple{Any}",
    "page": "LightQuery.jl",
    "title": "LightQuery.@_",
    "category": "macro",
    "text": "macro _(body::Expr)\n\nCreate an Nameless object. The arguments are inside the body; the first arguments is _, the second argument is __, etc. Also stores a quoted version of the function.\n\njulia> using LightQuery\n\njulia> 1 |> @_(_ + 1)\n2\n\njulia> map(@_(__ - _), (1, 2), (2, 1))\n(1, -1)\n\njulia> @_(_ + 1).expression\n:(_ + 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.jl-1",
    "page": "LightQuery.jl",
    "title": "LightQuery.jl",
    "category": "section",
    "text": "Modules = [LightQuery]"
},

]}
