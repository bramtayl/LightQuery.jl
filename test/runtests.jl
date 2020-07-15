using Documenter: doctest
using LightQuery
using LightQuery: my_flatten, my_all, partial_map, my_setdiff, named_tuple
using Test: @test, @test_throws

doctest(LightQuery)

# TODO: figure out a better way to trigger this
@test_throws StackOverflowError iterate(
    InnerJoin(By(Int[], identity), By(Int[], identity)),
    (nothing, nothing, false, false),
)

A = (true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false)
@test !my_all(A)
@test A == partial_map(&, true, A)
@test A == partial_map(&, true, A, A)
@test my_setdiff(A, (true,)) == (false,)
@test name"k"(named_tuple((a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8, i = 9, j = 10, k = 11, l = 12, m = 13, n = 14, o = 15, p = 16, q = 17, r = 18))) == 11
