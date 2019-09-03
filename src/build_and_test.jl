using Pkg
Pkg.build()
Pkg.test(; coverage = true)
