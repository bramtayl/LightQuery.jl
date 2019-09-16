using Pkg: develop, instantiate, PackageSpec
develop(PackageSpec(path=pwd()))
using LightQuery

instantiate()
using Documenter: deploydocs, makedocs

makedocs(sitename = "LightQuery.jl", modules = [LightQuery], doctest = false)
deploydocs(repo = "github.com/bramtayl/LightQuery.jl.git")
