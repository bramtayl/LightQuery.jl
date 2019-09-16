@static if VERSION >= v"1.1"
    using Pkg: instantiate
    instantiate()

    using Coverage: process_folder
    using Coverage.Codecov: submit
    using Coverage.LCOV: readfolder

    submit(
        filter(
            let prefix = joinpath(pwd(), "src", "")
                coverage -> startswith(coverage.filename, prefix)
            end,
            readfolder(".")
        )
    )
end
