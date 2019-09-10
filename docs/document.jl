using Pkg: instantiate
instantiate()

using LightQuery
import Documenter: makedocs, deploydocs

makedocs(sitename = "LightQuery.jl", modules = [LightQuery], doctest = false)
deploydocs(repo = "github.com/bramtayl/LightQuery.jl.git")
