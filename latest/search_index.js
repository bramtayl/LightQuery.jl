var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#LightQuery.@_-Tuple{Expr}",
    "page": "Home",
    "title": "LightQuery.@_",
    "category": "macro",
    "text": "macro _(body::Expr)\n\nAnother syntax for anonymous functions. The arguments are inside the body; the first arguments is _, the second argument is __, etc.\n\njulia> using LightQuery\n\njulia> 1 |> (@_ _ + 1)\n2\n\njulia> map((@_ __ - _), (1, 2), (2, 1))\n(1, -1)\n\n\n\n\n\n"
},

{
    "location": "index.html#LightQuery.@query-Tuple{Any}",
    "page": "Home",
    "title": "LightQuery.@query",
    "category": "macro",
    "text": "macro query(body::Expr)\n\nQuery your code. If body is a chain head_ |> tail_, recur on head. If tail is a function call, and the function ends with a number (the parity), anonymize and quote arguments past that parity. Either way, anonymize the whole tail, then call it on head.\n\njulia> using LightQuery\n\njulia> call(source1, source2, anonymous, quoted) = anonymous(source1, source2);\n\njulia> @query 1 |> (_ - 2) |> abs(_) |> call2(_, 2, _ + __)\n3\n\njulia> @query 1 |> call2(_)\nERROR: LoadError: Expecting at least 2 argument(s)\n[...]\n\n\n\n\n\n"
},

{
    "location": "index.html#LightQuery.jl-1",
    "page": "Home",
    "title": "LightQuery.jl",
    "category": "section",
    "text": "Modules = [LightQuery]"
},

]}
