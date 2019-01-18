import LightQuery
import Documenter: makedocs, deploydocs

makedocs(
    modules = [LightQuery],
    sitename = "LightQuery.jl",
    strict = true,
)

deploydocs(
    repo = "github.com/bramtayl/LightQuery.jl.git"
)
