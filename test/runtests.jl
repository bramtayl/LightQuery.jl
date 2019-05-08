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

@testset "macros" begin
    @test (@> 1 |> (@> _ |> _ + 1)) == 2
end

struct MyType
    a::Int
    b::Float64
end

import Base: propertynames
@inline propertynames(::MyType) = (:a, :b)

@testset "named_tuples" begin
    @name @test @inferred(getindex((a = 1, b = 1.0), :a)) == 1
    @name @test @inferred(getindex((a = 1, b = 1.0), (:a,))) == (a = 1,)
    @name @test @inferred(transform((a = 1,), b = 1.0)) == (a = 1, b = 1.0)
    @name @test @inferred(merge((a = 1, b = 1.0), (b = 2.0, c = "b"))) ==
        (a = 1, b = 2.0, c = "b")
    @name @test @inferred(remove((a = 1, b = 1.0), :b)) == (a = 1,)
    @name @test @inferred(rename((a = 1, b = 1.0), c = :a)) == (b = 1.0, c = 1)
    @name @test @inferred(gather((a = 1, b = 1.0, c = 1//1), d = (:a, :c))) ==
        (b = 1.0, d = (a = 1, c = 1//1))
    @name @test @inferred(spread((b = 1.0, d = (a = 1, c = 1//1)), :d)) ==
        (b = 1.0, a = 1, c = 1//1)
    @name @inferred named_tuple(MyType(1, 1.0)) == (a = 1, b = 1.0)
    @test (@name @inferred NamedTuple((a = 1, b = 1.0))) == (a = 1, b = 1.0)
end

f(x) = (x, x + 0.0)
f2(x) = x < 3 ? (x, x + 0.0) : (x, missing)

@testset "Unzip" begin
    @test collect(zip([1, 2], [1.0, 2.0])) == [(1, 1.0), (2, 2.0)]
    @test isequal(
        unzip(Generator(f, [1, missing])),
        (Union{Missing, Int64}[1, missing], Union{Missing, Float64}[1.0, missing])
    )
    @test_throws ErrorException unzip(Generator(x -> error(), 1:1))
    @test (@inferred unzip(zip([1], [1.0]))) == ([1], [1.0])
    @test (@inferred unzip([(1, 1.0)])) == ([1], [1.0])
    @test (@inferred unzip(Tuple{Int, Float64}[])) == (Int64[], Float64[])
    @test (@inferred unzip(over(Tuple{Int, Float64}[], identity))) == (Int64[], Float64[])
    @test isequal(
         unzip(Generator(f2, [1, 2, 3])),
         ([1, 2, 3], Union{Missing, Float64}[1.0, 2.0, missing])
    )
    @test isequal(
         unzip(Generator(f2, Filter(x -> true, [1, 2, 3]))),
         ([1, 2, 3], Union{Missing, Float64}[1.0, 2.0, missing])
    )
end

@testset "iterators" begin
    @test collect(Group(By(Int[], identity))) == []
    @test Group(By([1], iseven)) |> collect == [false => [1]]
    @test (Length(1:2, 2) |> collect == [1, 2])
    @test isequal(collect(Join(By([1], identity), By([], identity))), [(1, missing)])
    @test isequal(collect(Join(By([], identity), By([1], identity))), [(missing, 1)])
    @test collect(Join(By([], identity), By([], identity))) == []
end

@testset "LightQuery" begin
    @name @test @inferred(collect(to_rows((a = [1, 2], b = [1.0, 2.0])))) ==
        [(a = 1, b = 1.0), (a = 2, b = 2.0)]
    @name @test @inferred(to_columns(to_rows((a = [1, 2], b = [1.0, 2.0])))) ==
        (a = [1, 2], b = [1.0, 2.0])
    @name @test @inferred(make_columns([(a = 1, b = 1.0), (a = 2, b = 2.0)])) ==
        (a = [1, 2], b = [1.0, 2.0])
    @name @inferred(make_columns(to_rows((a = Int[], b = Float64[])))) ==
        ((a = Int64[]), (b = Float64[]))
    @name @inferred(make_columns(over(to_rows((a = Int[], b = Float64[])), identity))) ==
        ((a = Int64[]), (b = Float64[]))
    @name @test_throws ErrorException Generator(x -> error(), 1:2) |> make_columns
end
