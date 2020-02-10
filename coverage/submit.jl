@static if VERSION > v"1.3"
    using Coverage
    coverage = process_folder()
    coverage = append!(coverage, process_folder("deps"))
    coverage = merge_coverage_counts(coverage, filter!(
        let prefixes = (joinpath(pwd(), "src", ""), joinpath(pwd(), "deps", ""))
            c -> any(p -> startswith(c.filename, p), prefixes)
        end,
        LCOV.readfolder("."))
    )
    Codecov.submit(coverage)
end
