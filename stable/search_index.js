var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#LightQuery.Name",
    "page": "Home",
    "title": "LightQuery.Name",
    "category": "type",
    "text": "struct Name{T} end\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred Name(:a)((a = 1, b = 2.0,))\n1\n\njulia> @inferred merge(Name(:a), Name(:b))\nNames{(:a, :b)}()\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Nameless",
    "page": "Home",
    "title": "LightQuery.Nameless",
    "category": "type",
    "text": "A container for a function and the expression that generated it\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.Names",
    "page": "Home",
    "title": "LightQuery.Names",
    "category": "type",
    "text": "struct Names{T} end\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred Names(:a)((a = 1, b = 2.0,))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.based_on-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.based_on",
    "category": "method",
    "text": "based_on(data; assignments...)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred based_on((a = 1, b = 2.0), c = @_ _.a + _.b)\n(c = 3.0,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather-Tuple{Any,Name,Names}",
    "page": "Home",
    "title": "LightQuery.gather",
    "category": "method",
    "text": "gather(data, new_column::Name, columns::Names)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred gather((a = 1, b = 2.0, c = \"c\"), Name(:d), Names(:a, :c))\n(b = 2.0, d = (a = 1, c = \"c\"))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.name-Union{Tuple{T}, Tuple{Any,Names{T}}} where T",
    "page": "Home",
    "title": "LightQuery.name",
    "category": "method",
    "text": "name(data, names::Names)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred name((a = 1, b = 2.0), Names(:c, :d))\n(c = 1, d = 2.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.named-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.named",
    "category": "method",
    "text": "named(data)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> named(:a => 1)\n(first = :a, second = 1)\n\njulia> @inferred named((a = 1, b = 2.0))\n(a = 1, b = 2.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.remove-Union{Tuple{T}, Tuple{Any,Names{T}}} where T",
    "page": "Home",
    "title": "LightQuery.remove",
    "category": "method",
    "text": "remove(data, columns::Names)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred remove((a = 1, b = 2.0), Names(:b))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rename-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.rename",
    "category": "method",
    "text": "rename(data; renames...)\n\njulia> using LightQuery\n\njulia> rename((a = 1, b = 2.0), c = Name(:a))\n(b = 2.0, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.select-Union{Tuple{T}, Tuple{Any,Names{T}}} where T",
    "page": "Home",
    "title": "LightQuery.select",
    "category": "method",
    "text": "select(data, columns::Names)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred select((a = 1, b = 2.0), Names(:a))\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.spread-Tuple{Any,Name}",
    "page": "Home",
    "title": "LightQuery.spread",
    "category": "method",
    "text": "spread(data, column::Name)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred spread((b = 2.0, d = (a = 1, c = \"c\")), Name(:d))\n(b = 2.0, a = 1, c = \"c\")\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.transform-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.transform",
    "category": "method",
    "text": "transform(data; assignments...)\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> @inferred transform((a = 1, b = 2.0), c = @_ _.a + _.b)\n(a = 1, b = 2.0, c = 3.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.unname-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.unname",
    "category": "method",
    "text": "unname\n\njulia> using LightQuery\n\njulia> using Test: @inferred\n\njulia> unname(:a => 1)\n(:a, 1)\n\njulia> @inferred unname((a = 1, b = 2.0))\n(1, 2.0)\n\njulia> @inferred unname((1, 2.0))\n(1, 2.0)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@>-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.@>",
    "category": "macro",
    "text": "macro >(body)\n\nIf body is in the form body_ |> tail_, call @_ on tail, and recur on body.\n\njulia> using LightQuery\n\njulia> @> 0 |> _ + 1 |> _ - 1\n0\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@_-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.@_",
    "category": "macro",
    "text": "macro _(body::Expr)\n\nCreate an Nameless object. The arguments are inside the body; the first arguments is _, the second argument is __, etc. Also stores a quoted version of the function.\n\njulia> using LightQuery\n\njulia> 1 |> @_(_ + 1)\n2\n\njulia> map(@_(__ - _), (1, 2), (2, 1))\n(1, -1)\n\njulia> @_(_ + 1).expression\n:(_ + 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.jl-1",
    "page": "Home",
    "title": "LightQuery.jl",
    "category": "section",
    "text": "Modules = [LightQuery]"
},

]}
