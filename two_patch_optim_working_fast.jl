# Optimal Harvest of a 2-patch fishery given a fixed dispersal matrix

# New in this version:
# Added a padding of zeros around the value matrix to avoid boundary errors

using LinearAlgebra
using Optim
using Interpolations
using BenchmarkTools

const convcrit = 1e-3
const carrying_capacity = 100
const r = 0.8
const discount_factor = 0.9
const ngrid = 5
const stock_grid = collect(range(0.0, carrying_capacity, length = ngrid))
const dispersal = [[0.75 0.25]; [0.25 0.75]]

function stock_growth(harvest, stock)
    stock .- harvest .+ r .* stock .* (1 .- stock ./ carrying_capacity)
end

function stock_next(harvest, stock)
    new_stock = dispersal * stock_growth.(harvest, stock)
end

function profit(harvest, stock)
    profit = sum(harvest)
end

function absolute_difference(a,b)
    abs.(a .- b)
end

function sup_norm(a,b)
     maximum(absolute_difference.(a,b))
end

function check_convergence(a, b)
    sup_norm(a,b) < convcrit
end

function total_reward(current_reward, future_reward)
    current_reward + discount_factor*future_reward
end

function future_reward(harvest, stock, value_interp)
    future_stock = stock_next(harvest, stock)
    value_interp(future_stock...)
end

function bellman(harvest, stock, value_interp)
    cr = profit(harvest, stock)
    fr = future_reward(harvest, stock, value_interp)
    total_reward(cr, fr)
end

function objective(stock, value_interp)
    h -> - bellman(h, stock, value_interp)
end

function optimize_objective(objctv, stock)
    opt = optimize(objctv, fill(0.0, 2), stock,  stock/2, Fminbox())
    (opt.minimizer, -opt.minimum)
end

function optimal_harvest(stock, value_interp)
    objctv = objective(stock, value_interp)
    optimize_objective(objctv, stock)
end

function edge_objective(stock, value_interp)
    h -> - bellman([stock[i] != 0.0 ? h : 0.0 for i=1:2], stock, value_interp)
end

function edge_optimize_objective(objctv, stock)
    lower_bound = 0.0
    upper_bound = stock[stock .!= 0.0][1]
    opt = optimize(objctv, lower_bound, upper_bound, GoldenSection())
    (opt.minimizer, -opt.minimum)
end

function edge_optimal_harvest(stock, value_interp)
    objctv = edge_objective(stock, value_interp)
    edge_optimize_objective(objctv, stock)
end

function value_interpolator(value)
    LinearInterpolation((stock_grid, stock_grid), value)
end

function update_edges!(policy, value, value_interp)
    for idA = 2:ngrid
        stockA = stock_grid[idA]
        argmax, max = edge_optimal_harvest([stockA, 0.0], value_interp)
        policy[idA, 1, 1] = argmax
        value[idA, 1] = max
    end
    for idB = 2:ngrid
        stockB = stock_grid[idB]
        argmax, max = edge_optimal_harvest([0.0, stockB], value_interp)
        policy[1, idB, 2] = argmax
        value[1, idB] = max
    end
    nothing
end

function update_center!(policy, value, value_interp)
    for idA = 2:ngrid
        stockA = stock_grid[idA]
        for idB = 2:ngrid
            stockB = stock_grid[idB]
            argmax, max = optimal_harvest([stockA, stockB], value_interp)
            policy[idA, idB, :] = argmax
            value[idA, idB] = max
        end
    end
    nothing
end

function update!(policy, value)
    value_interp = value_interpolator(value)
    update_edges!(policy, value, value_interp)
    update_center!(policy, value, value_interp)
    nothing
end

function update_value_only!(policy, value)
    value_interp = value_interpolator(value)
    for a = 1:ngrid, b = 1:ngrid
        harvest = policy[a,b,:]
        stock = [stock_grid[a], stock_grid[b]]
        value[a,b] = bellman(harvest, stock, value_interp)
    end
end

function value_iteration()
    value = zeros(ngrid, ngrid)
    policy = zeros(ngrid, ngrid, 2)
    # Run 10 Burn-Ins optimizing harvest each time
    for t = 1:100
        update!(policy, value)
    end
    # Now re-maximize harvest & check convergence every 10th iteration
    counter = 0
    converged = false
    old_value = copy(value)
    while (converged == false) & (counter < 1000)
        update!(policy, value)
        for t = 1:100
            update_value_only!(policy, value)
        end
        converged = check_convergence(value, old_value)
        old_value = copy(value)
        counter += 1
    end
    (policy, value, counter)
end

p,v,c = value_iteration()
println(c)
println(v)
