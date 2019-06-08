if get(ENV, "TRAVIS_OS_NAME", nothing) == "linux" &&
    get(ENV, "TRAVIS_JULIA_VERSION", nothing) == "1.1"
    using Pkg: instantiate
    using Coverage.Codecov: submit, process_folder
    instantiate()
    submit(process_folder())';
end
