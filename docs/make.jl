using LightQuery
using Documenter: deploydocs, makedocs
makedocs(sitename = "LightQuery.jl", modules = [LightQuery], doctest = false)
deploydocs(repo = "github.com/bramtayl/LightQuery.jl.git")
