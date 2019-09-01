import LightQuery
import Documenter: makedocs, deploydocs

makedocs(sitename = "LightQuery.jl", modules = [LightQuery])
deploydocs(repo = "github.com/bramtayl/LightQuery.jl.git")
