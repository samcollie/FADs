# Goal: Find the optimal number and placement of FADs in a simple fishing ground
#       This is the "simplest possible" model.

# Notes: Make sure you only read the newest version of the Julia documentation...
# https://docs.julialang.org/en/v1/
# A lot of the stuff online pertains to beta versions (prior to 1.0) that
# doesn't apply anymore. Just search the docs in the link above instead.

# Step 0: Load Packages
using LinearAlgebra
using Optim
using Interpolations

## Initialize global paramaters

# Parameters for the 'patches'
carrying_capacity = 100
r = 0.8     # A parameter for the Gordon-Schaefer logistic growth function
dim = 2     # The number of patches on one edge of the [square] fishing ground
npatches = dim^2    # Total number of patches

# Parameters for the value function iteration
ngrid = 10  # Grid size for the state-space (the stock in a given patch)
stock_grid = range(0, carrying_capacity, length=ngrid)
discount_factor = 0.9

## Define Functions

# Gordon-Schaefer Stock Growth Function
function stock_growth(stock, harvest)
    stock - harvest + r * stock .* (1 .- stock/carrying_capacity)
end

# Next period stock
function stock_next(harvest, stock, dispersal)
    dispersal * stock_growth(stock,harvest)
end

# Find the maximum absolute difference of two vectors a & b
function sup_norm(a,b)
     maximum(abs.(a - b))
end

# See if the max abs. difference is larger than the convergence criterion.
function check_convergence(a,b)
    sup_norm(a,b) < convcrit
end

# Profit in this time period given harvest h
function profit(harvest)
    harvest   # Keep this simple for now
end

# Objective = The thing to maximize.
# Equal to this period's profit from harvest plus the discounted future reward
function objective(harvest, stock, dispersal, patch_value)
    # The profit in this period
    current_reward = profit(harvest)
    # The stock in the next period
    future_stock = stock_next(harvest, stock, dispersal)
    # The future reward (continuation value)
    interp = LinearInterpolation(stock_grid, patch_value)
    future_reward = interp(future_stock)
    # Put it all together!
    current_reward + discount_factor*future_reward
end

# Initialize the continuation value at zero
value = zeros(ngrid, npatches)

# An example dispersal matrix
dispersal = (ones(npatches,npatches)/npatches + I)/2


pi = objective(32, 69, dispersal, value[:,1])
println(pi)



# stock = (1/2)*carrying_capacity*ones(npatches)
#
# converged = false
#
# while converged == false
#
#     # Harvest 50% of the stock in patch 1
#     harvest = zeros(npatches)
#     harvest[1] = test_stock[1]/2
#
#     # Get the stock in the next period when harvest is applied
#     new_stock = stock_next(harvest, stock, test_dispersal)
#     println(new_stock)
#
#     # The SUP-Norm.
#     # The largest absolute difference between the old & new stock
#     global converged = check_convergence(stock, new_stock)
#
#     # After checking for convergence, update the stock.
#     global stock = new_stock
#
# end
