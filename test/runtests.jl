using LightQuery
import Documenter: makedocs, deploydocs

makedocs(
    sitename = "LightQuery.jl",
    strict = true,
    modules = [LightQuery]
)

deploydocs(
    repo = "github.com/bramtayl/LightQuery.jl.git"
)

using Test

@inline Base.propertynames(p::Pair) = (:first, :second);

@testset "macros" begin
    @test (@> 1 |> (@> _ |> _ + 1)) == 2
end

@testset "named_tuples" begin
    @name @test @inferred(getindex((a = 1, b = 1.0), :a)) == 1
    @name @test @inferred(getindex((a = 1, b = 1.0), (:a,))) == (a = 1,)
    @name @test @inferred(named_tuple(1 => 1.0)) == (first = 1, second = 1.0)
    @name @test @inferred(transform((a = 1,), b = 1.0)) == (a = 1, b = 1.0)
    @name @test @inferred(remove((a = 1, b = 1.0), :b)) == (a = 1,)
    @name @test @inferred(rename((a = 1, b = 1.0), c = :a)) == (b = 1.0, c = 1)
    @name @test @inferred(gather((a = 1, b = 1.0, c = 1//1), d = (:a, :c))) ==
        (b = 1.0, d = (a = 1, c = 1//1))
    @name @test @inferred(spread((b = 1.0, d = (a = 1, c = 1//1)), :d)) ==
        (b = 1.0, a = 1, c = 1//1)
end

f(x) = (x, x + 0.0)
test(x) = unzip(x, 2)
f2(x) = x < 3 ? (x, x + 0.0) : (x, missing)

@testset "Unzip" begin
    @test collect(zip([1, 2], [1.0, 2.0])) == [(1, 1.0), (2, 2.0)]
    @test isequal(
        test(Generator(f, [1, missing])),
        (Union{Missing, Int64}[1, missing], Union{Missing, Float64}[1.0, missing])
    )
    @test_throws ErrorException test(Generator(x -> error(), 1:1))
    @test (@inferred test(zip([1], [1.0]))) == ([1], [1.0])
    @test (@inferred test([(1, 1.0)])) == ([1], [1.0])
    @test isequal(
         test(Generator(f2, [1, 2, 3])),
         ([1, 2, 3], Union{Missing, Float64}[1.0, 2.0, missing])
    )
    @test isequal(
         test(Generator(f2, Filter(x -> true, [1, 2, 3]))),
         ([1, 2, 3], Union{Missing, Float64}[1.0, 2.0, missing])
    )
end

@testset "iterators" begin
    @test Group(By([1], iseven)) |> collect == [false => [1]]
    @test (Length(1:2, 2) |> collect == [1, 2])
    @test isequal(collect(Join(By([1], identity), By([], identity))), [1 => missing])
    @test isequal(collect(Join(By([], identity), By([1], identity))), [missing => 1])
end

@testset "LightQuery" begin
    @name @test @inferred(collect(rows((a = [1, 2], b = [1.0, 2.0])))) ==
        [(a = 1, b = 1.0), (a = 2, b = 2.0)]
    @name @test @inferred(columns(rows((a = [1, 2], b = [1.0, 2.0])))) ==
        (a = [1, 2], b = [1.0, 2.0])
    @name @test @inferred(make_columns([(a = 1, b = 1.0), (a = 2, b = 2.0)])) ==
        (a = [1, 2], b = [1.0, 2.0])
    @name @test_throws ErrorException Generator(x -> error(), 1:2) |> make_columns
end
