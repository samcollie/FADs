# Attempt at integrating optimization over multiple (2) patches - not done yet...

# Load Packages
using LinearAlgebra
using Optim
using Interpolations
using IterTools

# Parameters

const carrying_capacity = 100
const r = 0.8
const discount_factor = 0.9
const ngrid = 3
const stock_grid = range(0.0, carrying_capacity, length = ngrid)
const npatches = 2
const convcrit = 1e-6

# Need vector with all combinations of stock levels across patches:
state_space = vec(collect(product([stock_grid for i=1:npatches]...)))
println("\n The State Space")
println(state_space)

# Define functions

function stock_growth(stock, harvest)
    stock - harvest + r * stock .* (1 .- stock/carrying_capacity)
end

# We want to be incorporating dispersal at this point, right? Prev. code had a
# sample dispersal matrix, so I'm assuming thats what we'll use here eventually...
function stock_next(harvest, stock, dispersal)
    new_stock = dispersal * stock_growth(stock,harvest)
end

function profit(harvest)
    harvest
end

function sup_norm(a,b)
     maximum(abs.(a .- b))
end

function check_convergence(a,b)
    sup_norm(a,b) < convcrit
end

function bellman(harvest, stock, valu_interp)
    current_reward = profit(harvest)
    future_stock = stock_next(harvest, stock)
    future_reward = valu_interp(future_stock)
    current_reward + discount_factor*future_reward
end

function optimal_harvest(stock, valu_interp)
    objective = h -> - bellman(h, stock, valu_interp)
    result = optimize(objective, 0.0, stock)
    -result.minimum
end

function update_valu(valu)
    valu_next = fill(0.0, ngrid)
    valu_interp = LinearInterpolation(stock_grid, valu) # is this where I would
    # replace stock_grid with state_space vector? Or keep everything in reference
    # to stock_grid until actually running the iterations?
    for (idx, stock) in enumerate(stock_grid)
        valu_next[idx] = optimal_harvest(stock, valu_interp)
    end
    valu_next
end

function valu_iteration()
    valu = zeros(ngrid)
    valu_next = zeros(ngrid)
    counter = 0
    converged = false
    while (converged == false) & (counter < 10000)
        valu_next = update_valu(valu)
        converged = check_convergence(valu, valu_next)
        valu = copy(valu_next)
        counter += 1  # Add 1 to the counter
    end
    counter
end
