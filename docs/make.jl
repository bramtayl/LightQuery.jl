import Documenter

Documenter.deploydocs(
    repo = "github.com/bramtayl/LightQuery.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
    julia = "1.0"
)
