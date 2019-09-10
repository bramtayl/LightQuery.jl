if [[ $TRAVIS_JULIA_VERSION == 1.2 ]] && [[ $TRAVIS_OS_NAME == linux ]]
    then julia --project=docs docs/document.jl
fi
