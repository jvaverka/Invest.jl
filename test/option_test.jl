using Invest, Test

@testset "American" begin
    american = American(1.0, 2.0, 1.1, 0.9, 0.01, 5 / 12)
    @test isa(american, American)
end

@testset "European" begin
    european = European(1.0, 2.0, 0.1, 0.3, 5 / 12)
    @test isa(european, European)
end

# TODO: Add tests for American options with calculated σ

@testset "Pricing" begin
    e = European(90.0, 85.0, 0.1, 0.3, 6 / 12)
    @test isa(e, European)
    C, P = price(e)
    @test round(C, digits=2) == 12.69
    @test round(P, digits=2) == 3.54
    @test round(price(European(437.5, 460.0, 0.0125, 0.42, 12 / 12))[2], digits=2) == 82.85
    @test round(price(European(20.0, 20.0, 0.06, 0.2, 3 / 12))[1], digits=5) == 0.94938
    @test round(price(European(20.0, 20.0, 0.06, 0.2, 3 / 12))[2], digits=5) == 0.65162
    @test round(price(European(50.0, 50.0, 0.10, 0.3, 3 / 12))[2], digits=6) == 2.375941
end

# TODO: Add tests for underlying derivative price of put option

@testset "Greeks" begin
    e = European(40.0, 45.0, 0.08, 0.3, 4 / 12)
    @test isa(e, European)
    @test !isat(e)
    @test isat(European(2.0, 2.0, 0.01, 0.2, 1 / 12))
    @test round(Δ(e)[1], digits=2) == 0.33
    @test round(Γ(e), digits=3) == 0.052
    @test round(Θ(e), digits=4) == -0.0129
    C, _ = dprice(e, 3, 1 / 52)
    @test round((C), digits=2) == 2.6
end

