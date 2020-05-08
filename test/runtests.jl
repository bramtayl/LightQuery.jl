import LightQuery
using Documenter: doctest

doctest(LightQuery)

using LightQuery: By, InnerJoin
using Test: @test_throws

# TODO: figure out a better way to trigger this
@test_throws StackOverflowError iterate(
    InnerJoin(By(Int[], identity), By(Int[], identity)),
    (nothing, nothing, false, false),
)
