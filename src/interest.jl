# Formulas used for Chapter 2 exercises
yearly_compounded_interest(i, r, y) = (i * (1 + (r / 100)))^y

find_effective_rate(i, n) = (1 + i / n)^n - 1

"internal rate of return"
function irr(func1, func2, init, stop)
    sol = Float64[]
    λₖ = func1(init)
    λₖ₊₁ = λₖ - func1(λₖ) / func2(λₖ)
    push!(sol, float(λₖ))
    if stop == 0
        return [λₖ]
    end
    push!(sol, float(λₖ₊₁))
    if stop == 1
        return [λₖ, λₖ₊₁]
    end
    for k in range(2; stop=stop)
        λₖ = λₖ₊₁
        λₖ₊₁ = λₖ - func1(λₖ) / func2(λₖ)
        push!(sol, float(λₖ₊₁))
    end
    return sol
end

"net present value"
npv(inv, val, rate, year) = -inv + val / (1 + rate)^year

"annual equivalent rate"
aer(r, n) = (1 + r / n)^n - 1

"continuously compounded interest"
cci(r) = exp(r) - 1

"present value"
function pv(p, r, n)
    interest = 0.0
    for i in range(0, n - 1; step=1)
        interest += (1 + r)^-i
    end
    return p * interest
end

# From Lecture Notes

"present value"
function present_value(s, r)
    return mapreduce((k, x) -> x / (1 + r)^k, +, 0:(length(s) - 1), s)
end
