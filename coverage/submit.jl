using Pkg: instantiate
instantiate()

using Coverage: process_folder
using Coverage.Codecov: submit

using Pkg: instantiate
instantiate()

using Coverage: process_folder
using Coverage.Codecov: submit
using Coverage.LCOV: readfolder

submit(
    @static if VERSION >= v"1.0"
        filter(
            let prefix = joinpath(pwd(), "src", "")
                coverage -> startswith(coverage.filename, prefix)
            end,
            readfolder(".")
        )
    else
        process_folder()
    end
)
