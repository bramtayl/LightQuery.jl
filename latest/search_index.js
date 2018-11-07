var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#LightQuery.Nameless",
    "page": "Home",
    "title": "LightQuery.Nameless",
    "category": "type",
    "text": "A container for a function and the expression that generated it\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.based_on-Tuple{NamedTuple}",
    "page": "Home",
    "title": "LightQuery.based_on",
    "category": "method",
    "text": "based_on(data; assignments...)\n\njulia> using LightQuery\n\njulia> based_on((a = 1, b = 2), c = @_ _.a + _.b)\n(c = 3,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.gather-Tuple{NamedTuple,Symbol,Vararg{Symbol,N} where N}",
    "page": "Home",
    "title": "LightQuery.gather",
    "category": "method",
    "text": "gather(data, new_column, columns...)\n\njulia> using LightQuery\n\njulia> gather((a = 1, b = 2, c = 3), :d, :a, :c)\n(b = 2, d = (a = 1, c = 3))\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.in_common-Tuple{NamedTuple,NamedTuple}",
    "page": "Home",
    "title": "LightQuery.in_common",
    "category": "method",
    "text": "in_common(data1, data2)\n\njulia> using LightQuery\n\njulia> data1 = (a = 1, b = 2); data2 = (a = 1, c = 3);\n\njulia> in_common(data1, data2)\n(:a,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.name-Tuple{Any,Vararg{Any,N} where N}",
    "page": "Home",
    "title": "LightQuery.name",
    "category": "method",
    "text": "name(data, columns...)\n\njulia> using LightQuery\n\njulia> name((1, 2), :a, :b)\n(a = 1, b = 2)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.remove-Tuple{Any,Vararg{Any,N} where N}",
    "page": "Home",
    "title": "LightQuery.remove",
    "category": "method",
    "text": "remove(data, columns...)\n\njulia> using LightQuery\n\njulia> remove((a = 1, b = 2), :b)\n(a = 1,)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.rename-Tuple{NamedTuple,Vararg{Any,N} where N}",
    "page": "Home",
    "title": "LightQuery.rename",
    "category": "method",
    "text": "rename(data; renames...)\n\njulia> using LightQuery\n\njulia> rename((a = 1, b = 2), :a => :c)\n(b = 2, c = 1)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.same-Tuple{NamedTuple,NamedTuple}",
    "page": "Home",
    "title": "LightQuery.same",
    "category": "method",
    "text": "same([data1::NamedTuple, data2::NamedTuple])\n\njulia> using LightQuery\n\njulia> data1 = (a = 1, b = 2); data2 = (a = 1, c = 3);\n\njulia> same(data1, data2)\ntrue\n\njulia> same()(data1, data2)\ntrue\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.same_at-Tuple{NamedTuple,NamedTuple,Vararg{Symbol,N} where N}",
    "page": "Home",
    "title": "LightQuery.same_at",
    "category": "method",
    "text": "same_at([data1::NamedTuple, data2::NamedTuple], columns::Symbol...)\n\njulia> using LightQuery\n\njulia> data1 = (a = 1, b = 2); data2 = (a = 1, b = 3);\n\njulia> same_at(data1, data2, :a)\ntrue\n\njulia> same_at(:a)(data1, data2)\ntrue\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.select-Tuple{NamedTuple,Vararg{Symbol,N} where N}",
    "page": "Home",
    "title": "LightQuery.select",
    "category": "method",
    "text": "select([data], columns::Symbol...)\n\njulia> using LightQuery\n\njulia> data = (a = 1, b = 2, c = 3);\n\njulia> select(data, :a, :c)\n(a = 1, c = 3)\n\njulia> select(:a, :c)(data)\n(a = 1, c = 3)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.spread-Tuple{Any,Any}",
    "page": "Home",
    "title": "LightQuery.spread",
    "category": "method",
    "text": "spread(data, new_column)\n\njulia> using LightQuery\n\njulia> spread((b = 2, d = (a = 1, c = 3)), :d)\n(b = 2, a = 1, c = 3)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.transform-Tuple{NamedTuple}",
    "page": "Home",
    "title": "LightQuery.transform",
    "category": "method",
    "text": "transform(data; assignments...)\n\njulia> using LightQuery\n\njulia> transform((a = 1, b = 2), c = @_ _.a + _.b)\n(a = 1, b = 2, c = 3)\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@>-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.@>",
    "category": "macro",
    "text": "macro >(body)\n\nIf body is in the form body_ |> tail_, call @_ on tail, and recur on body.\n\njulia> using LightQuery\n\njulia> @> 0 |> _ + 1 |> _ - 1\n0\n\n\n\n\n\n"
},

{
    "location": "#LightQuery.@_-Tuple{Expr}",
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
