using LightQuery
import Documenter: makedocs, deploydocs

makedocs(sitename = "LightQuery.jl", strict = true, modules = [LightQuery])

if get(ENV, "TRAVIS_OS_NAME", nothing) == "linux" &&
    get(ENV, "TRAVIS_JULIA_VERSION", nothing) == "1.1"
    deploydocs(repo = "github.com/bramtayl/LightQuery.jl.git")
end
