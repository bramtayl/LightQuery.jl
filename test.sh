if test TRAVIS_JULIA_VERSION = "1.0"
    then /home/brandon/julia-1.3.0/bin/julia --project --code-coverage=user test.jl
    else /home/brandon/julia-1.3.0/bin/julia --project --code-coverage=user --code-coverage=tracefile-%p.info test.jl
fi
