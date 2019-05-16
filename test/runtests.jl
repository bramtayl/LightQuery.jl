using LightQuery
import Documenter: makedocs, deploydocs

makedocs(
    sitename = "LightQuery.jl",
    strict = true,
    modules = [LightQuery]
)

deploydocs(
    repo = "github.com/bramtayl/LightQuery.jl.git"
)
