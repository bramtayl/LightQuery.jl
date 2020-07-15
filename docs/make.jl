using LightQuery
import Documenter
using Documenter: deploydocs, makedocs
makedocs(
    sitename = "LightQuery.jl",
    modules = [LightQuery],
    doctest = false,
    pages = [
        "Usage and performance notes" => "index.md",
        "Beginner tutorial" => "beginner_tutorial.md",
        "Reshaping tutorial" => "reshaping_tutorial.md",
        "Interface" => "interface.md",
    ],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
)
deploydocs(repo = "github.com/bramtayl/LightQuery.jl.git")
