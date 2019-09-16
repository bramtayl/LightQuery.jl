if test "$TRAVIS_JULIA_VERSION" = "1.0"
    then julia --project --code-coverage=user test.jl
    else julia --project --code-coverage=tracefile-%p.info --code-coverage=user test.jl
fi
