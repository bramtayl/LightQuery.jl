import LightQuery
using Documenter: doctest

doctest(LightQuery)

using LightQuery: By, mix, @name
using Test: @test_throws

# TODO: figure out a better way to trigger this
@test_throws StackOverflowError iterate(
    (@name mix(:inner, By(Int[], identity), By(Int[], identity))),
    (nothing, nothing, false, false),
)
