using Distributions, UnPack

# NOTE: Refactor so that call & put options are distinguishable (at construction).

"""
  Option

Any contract representing the right, but not the
obligation to buy or sell a derivative at some point in time.
"""
abstract type Option end

# NOTE: American option doesn't have volatility (σ). Can it be Calculated?

"""
  American Option

An option which can be exercised at any point up to maturity.
"""
struct American <: Option
    S::Float64  # stock price
    K::Float64  # strike price
    u::Float64  # up-trend
    d::Float64  # down-trend
    r::Float64  # annual rate
    R::Float64  # risk-free rate => 1 + r
    q::Float64  # (R - d) / (u - d)
    T::Float64  # maturity in months
    t::Float64  # point in time
    American(S::Float64, K::Float64, u::Float64, d::Float64, r::Float64, T::Float64) = new(S, K, u, d, r / 12, 1 + r / 12, ((1 + r / 12) - d) / (u - d), T, 0.0)
    American(S::Float64, K::Float64, u::Float64, d::Float64, r::Float64, T::Float64, t::Int64) = new(S, K, u, d, r / 12, 1 + r / 12, ((1 + r / 12) - d) / (u - d), T, Float64(t))
end

"""
  European Option

An option which can only be exercised at maturity.
"""
struct European <: Option
    S::Float64  # stock price
    K::Float64  # strike price
    r::Float64  # rate
    σ::Float64  # volatility
    T::Float64  # maturity period
    t::Float64  # point in time
    European(S::Float64, K::Float64, r::Float64, σ::Float64, T::Float64) = new(S, K, r, σ, T, 0.0)
    European(S::Float64, K::Float64, r::Float64, σ::Float64, T::Float64, t::Int64) = new(S, K, r, σ, T, Float64(t))
end


# #######################
# Option Pricing formulas
# #######################

"""
    price(e::European)

Returns a tuple of the call & put premiums of a European Option.
"""
function price(e::European)
    @unpack S, K, r, σ, T, t = e
    d₁ = (log(S / K) + (r + 0.5σ^2) * (T - t)) / (σ * √(T - t))
    d₂ = d₁ - σ * √(T - t)
    C = S * cdf(Normal(), d₁) - K * exp(-r * T) * cdf(Normal(), d₂)
    P = C + K * exp(-r * T) - S  # put-call parity
    return (C, P)
end

# #######################
# Option Greeks
# #######################

"""
    isat(o::Option)

Returns true if an option is "at the money".
"""
function isat(o::Option)
  return o.S == o.K
end

"""
    Δ(o::Option, t=0.0)

Returns Δ of a European call & put option at some
point in time `t`.

Δ is the sensitivity of the option premium
with respect to the underlying derivative's price.

# Delta Hedging

- A portfolio of derivatives has a ``Δ`` equal to the sum of each component's ``Δ``
- A portfolio is delta neutral when its ``Δ = 0`` 

## Dynamic Hedging

A strategy of rebalancing a portfolio's components
such that the portfolio delta is zero.
"""
function Δ(o::Option)
  @unpack S, K, r, σ, T, t = o
  d₁ = (log(S / K) + (r + 0.5σ^2) * (T - t)) / (σ * √(T - t))
  C = cdf(Normal(), d₁)
  P = -cdf(Normal(), -d₁)
  return (C, P)
end

"""
    Γ(o::Option)

The Gamma measures the rate of change of a derivative's
``Δ`` with respect to its underlying stock price. 
"""
function Γ(o::Option)
  @unpack S, K, r, σ, T, t = o
  d₁ = (log(S / K) + (r + 0.5σ^2) * (T - t)) / (σ * √(T - t))
  return pdf(Normal(), d₁) / (S * σ * √(T - t))
end

"""
    Θ(o::Option)

The Theta measures the rate of change of a derivative's
price with respect to time (daily).
"""
function Θ(o::Option)
    @unpack S, K, r, σ, T, t = o
    d₁ = (log(S / K) + (r + 0.5σ^2) * (T - t)) / (σ * √(T - t))
    d₂ = d₁ - σ * √(T - t)
    first = (S * pdf(Normal(), d₁) * σ ) / (2 * √(T - t))
    second = r * K * exp(-r * (T - t)) * cdf(Normal(), d₂)
    return (-first - second) / 365
end

# NOTE: Might make sense to re-work method to calculate derivative value.

"""
    dprice(o::Option, δS, δt)

Return the value of a derivative using its option Greeks.

`dprice` returns a tuple of values for call & put respectively.

We know that:

'''math
\begin{aligned}
  Δ &= \frac{δP}{δS} \\
  Γ &= \frac{δ^{2}P}{δS^{2}} \\
  Θ &= \frac{δP}{δt} \\
\end{aligned}

∴ f ≈ Δ * δS + \frac{1}{2}Γ * (δS)^{2} + Θ * δt
'''
"""
function dprice(o::Option, δS, δt)
  return (cprice(o, δS, δt), pprice(o, δS, δt))
end

"""
    cprice(o::Option, δS, δt)

Return underlying derivative value of call option.
"""
function cprice(o::Option, δS, δt)
  C, _ = price(o)
  return C + Δ(o)[1] * δS + 0.5Γ(o) * δS^2 + Θ(o) * δt
end

# WARNING: Need to verifty `pprice` formula

"""
    pprice(o::Option, δS, δt)

Return underlying derivative value of put option.
"""
function pprice(o::Option, δS, δt)
  _, P = price(o)
  return P + Δ(o)[2] * δS + 0.5Γ(o) * δS^2 + Θ(o) * δt
end

