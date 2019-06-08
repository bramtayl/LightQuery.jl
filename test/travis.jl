if VERSION >= "1.1.0-rc1"
    Pkg.build(verbose=true)
else
    Pkg.build()
    Pkg.test(coverage = true)
end
