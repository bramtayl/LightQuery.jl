using LightQuery

import Documenter
Documenter.makedocs(
    modules = [LightQuery],
    format = :html,
    sitename = "LightQuery.jl",
    root = joinpath(dirname(dirname(@__FILE__)), "docs"),
    pages = Any["Home" => "index.md"],
    strict = true,
    linkcheck = true,
    checkdocs = :exports,
    authors = "Brandon Taylor"
)