if [[ -a .git/shallow ]]
    then
        git fetch --unshallow
fi
echo "$TRAVIS_JULIA_VERSION"
if [["$TRAVIS_JULIA_VERSION" == "1.0"]]
    then
        julia --project --code-coverage=tracefile-%p.info --code-coverage=user build_and_test.jl
    else
        julia --project --code-coverage=user build_and_test.jl
fi
