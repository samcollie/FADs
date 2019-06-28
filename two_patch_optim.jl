# Optimal Harvest of a 2-patch fishery given a fixed dispersal matrix

using LinearAlgebra
using Optim
using Interpolations
using BenchmarkTools

const convcrit = 1e-6
const carrying_capacity = 100
const r = 0.8
const discount_factor = 0.9
const ngrid = 3
const stock_grid = collect(range(0.0, carrying_capacity, length = ngrid))
const dispersal = [[0.75 0.25]; [0.25 0.75]]

function stock_growth(harvest, stock)
    stock .- harvest .+ r .* stock .* (1 .- stock ./ carrying_capacity)
end

function stock_next(harvest, stock)
    new_stock = dispersal * stock_growth(harvest, stock)
end

function profit(harvest, stock)
    if any(harvest .> stock)
        profit = -999.9
    else
        profit = sum(harvest)
    end
end

function sup_norm(a,b)
     maximum(abs.(a .- b))
end

function check_convergence(a, b)
    sup_norm(a,b) < convcrit
end

function bellman(harvest, stock, value_interp)
    current_reward = profit(harvest, stock)
    future_stock = stock_next(harvest, stock)
    future_reward = value_interp(future_stock...)
    current_reward + discount_factor*future_reward
end

function objective(stock, value_interp)
    h -> - bellman(h, stock, value_interp)
end

function optimize_objective(objctv)
    - optimize(objctv, [0.0, 0.0]).minimum
end

function optimal_harvest(stock, value_interp)
    objctv = objective(stock, value_interp)
    optimize_objective(objctv)
end

function value_interpolator(value)
    LinearInterpolation((stock_grid, stock_grid), value, extrapolation_bc = 0.0)
end

function update_value(value)
    value_next = zeros(ngrid, ngrid)
    value_interp = value_interpolator(value)
    for (idA, sA) in enumerate(stock_grid), (idB, sB) in enumerate(stock_grid)
        value_next[idA, idB] = optimal_harvest([sA,sB], value_interp)
    end
    value_next
end

# Think I should be adding state_space into this part...?
function value_iteration()
    value = zeros(ngrid, ngrid)
    value_next = copy(value)
    counter = 0
    converged = false
    while (converged == false) & (counter < 10000)
        value_next = update_value(value)
        converged = check_convergence(value, value_next)
        value = copy(value_next)
        counter += 1
    end
    value
end

value_iteration()

# Original:
# 2.140363 seconds (15.30 M allocations: 4.598 GiB, 21.03% gc time)
