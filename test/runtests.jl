import LightQuery
import Documenter: makedocs, deploydocs

makedocs(
    modules = [LightQuery],
    sitename = "LightQuery.jl",
    strict = true,
)

deploydocs(
    repo = "github.com/bramtayl/LightQuery.jl.git"
)

using LightQuery
using Test

@inline Base.propertynames(p::Pair) = (:first, :second);

test_Name(x) = (x)
test_spread(x) = spread(x, :d)
test_remove(x) = remove(x, :b)
test_rename(x) = rename(x, c = Name(:a))

@testset "named_tuples" begin
    @test @inferred(Name(:a)((a = 1, b = 1.0))) == 1
    @test @inferred(Names(:a)((a = 1, b = 1.0))) == (a = 1,)
    @test @inferred(named_tuple(:a => 1)) == (first = :a, second = 1)
    @test @inferred(transform((a = 1,), b = 1.0)) == (a = 1, b = 1.0)
    @test @inferred(test_remove((a = 1, b = 1.0))) == (a = 1,)
    @test @inferred(test_rename((a = 1, b = 1.0))) == (b = 1.0, c = 1)
    @test @inferred(gather((a = 1, b = 1.0, c = 1//1), d = Names(:a, :c))) ==
        (b = 1.0, d = (a = 1, c = 1//1))
    @test @inferred(test_spread((b = 1.0, d = (a = 1, c = 1//1)))) == (b = 1.0, a = 1, c = 1//1)
end


f(x) = (x, x + 0.0)
test(x) = unzip(x, 2)
f2(x) = iseven(x) ? (x, x + 0.0) : (x, missing)

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
         test(Generator(f2, Filter(x -> true, [1, 2, 3]))),
         ([1, 2, 3], Union{Missing, Float64}[missing, 2.0, missing])
    )
    @test isequal(
         test(Generator(f2, [1, 2, 3])),
         ([1, 2, 3], Union{Missing, Float64}[missing, 2.0, missing])
    )
    @test_throws ArgumentError zip([1], [1, 2])
end

@testset "iterators" begin
    @test Group(By([1], iseven)) |> collect == [false => [1]]
    @test (Length(1:2, 2) |> collect == [1, 2])
    @test isequal(collect(Join(By([1], identity), By([], identity))), [1 => missing])
    @test isequal(collect(Join(By([], identity), By([1], identity))), [missing => 1])
end

@testset "LightQuery" begin
    @test @inferred(collect(rows((a = [1, 2], b = [1.0, 2.0])))) == [(a = 1, b = 1.0), (a = 2, b = 2.0)]
    @test @inferred(columns(rows((a = [1, 2], b = [1.0, 2.0])))) == (a = [1, 2], b = [1.0, 2.0])
    @test @inferred(make_columns([(a = 1, b = 1.0), (a = 2, b = 2.0)])) == (a = [1, 2], b = [1.0, 2.0])
    @test_throws ErrorException Generator(x -> error(), 1:2) |> make_columns
end
