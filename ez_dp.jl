# Goal: Create a dynamic program maximizing profits in just 1 patch.
# This will help us learn Julia and illustrate value function iteration for you
# It gets a tad more complicated with multiple patches so lets start off easy.

# Notes: Make sure you only read the newest version of the Julia documentation...
# https://docs.julialang.org/en/v1/
# A lot of the stuff online pertains to beta versions (prior to 1.0) that
# doesn't apply anymore. Just search the docs in the link above instead.

# Step 0: Load Packages
# using LinearAlgebra
using Optim
using Interpolations
# using IterTools # You will get a warning that IterTools is depreciated. The internet says it isnt.

## Initialize global paramaters
#  (I'm not sure if it matters if I put 'global' before their name)


# Parameters for the Gordon-Schaefer logistic growth function
carrying_capacity = 100
r = 0.8

# Parameters for the value function iteration
ngrid = 10  # Grid size for the state-space (the stock in a given patch)
discount_factor = 0.9
convcrit = 1e-4  # Degree of precision to achieve convergence (larger number = faster convergence)

# Define the State-Space
stock_grid = range(0, carrying_capacity, length=ngrid)


## Define Functions

# Gordon-Schaefer Stock Growth Function
# Stock in next period = Current Stock minus Harvest plus regrowth
function stock_next(harvest, stock)
    # Update the Stock
    new_stock = stock - harvest + r * stock .* (1 .- stock/carrying_capacity)
    # Make sure the new stock is between 0 and 100
    if new_stock > 100.0
        new_stock = 100.0
    elseif new_stock < 0.0
        new_stock = 0.0
    end
    new_stock
end

# Profit in this time period given harvest h
function profit(harvest)
    # Keep this simple for now, Profit = harvest
    harvest
end

# Find the maximum absolute difference of two vectors a & b
function sup_norm(a,b)
     maximum(abs.(a - b))
end

# See if the max abs. difference is larger than the convergence criterion.
function check_convergence(a,b)
    sup_norm(a,b) < convcrit
end


# Objective = The thing to maximize.
# Equal to this period's profit from harvest plus the discounted future reward
function objective(harvest, stock, valu)
    # The profit in this period
    current_reward = profit(harvest)
    # The stock in the next period
    future_stock = stock_next(harvest, stock)
    # The future reward (continuation value)
    # See note below on the interpolation step
    interp = LinearInterpolation(stock_grid, valu)
    future_reward = interp(future_stock)
    # Put it all together!
    total_reward = current_reward + discount_factor*future_reward
    # Return the negative reward, since by defualt optimization methods minimize
    - total_reward
end

# Note: The continuation value ('valu') is equal to the maximum discounted profit
# associated with a given value of the state variable. For example, say there are
# 50 fish (stock=50), then the value function tells you how much profit you would
# make in the future starting with 50 fish, assuming you make all future harvest
# decisions optimally.

# Note on interpolation:
# The objective function above includes an interpolation step for the following
# reason. The matrix 'valu' defines the continuation value for each discrete step
# of the state variable (in this case stock_grid).
# So if stock grid = [0,10, ... , 90, 100], then we know the continuation value
# associated with each of those stock levels. But say we havest a bit and the next
# period stock is 55, then we need to know the continuation value at stock=55.
# That's why we interpolate, to get the half-way point between valu @ stock = 50
# & valu @ stock = 60.

## Ok now we have everything in place to do the value function iteration.
#  Basically, you set the valu matrix to something arbitrary. Then iteratively
#  update the value function, at each iteration choosing the optimal harvest for
#  every stock value in stock grid. Using that optimal harvest, you then update
#  the continuation value. Repeat this procedure until the value function does
#  not change anymore. (This is gaurenteed to work by the contraction mapping theorem).

# Initialize the continuation value at zero
valu = zeros(ngrid)

# Variables used to control the loop
global counter = 0  # A safety valve so this thing doesnt go on forever
global converged = false

while (converged == false) & (counter < 10000)

    # Create empty arrays to store results
    optimal_harvest = zeros(ngrid)
    valu_next = zeros(ngrid)

    # Loop through the state space & find the optimal harvest at
    # each level of the stock.
    for stock_idx = 1:ngrid
        # Grab the stock
        stock = stock_grid[stock_idx]
        # Minimize the objecive function
        # OK a little to unpack here....
        # The first argument of Optim is "h -> objective(h, stock, valu)"
        # This is called an anonymous function. Its saying, ok the funtion 'objective'
        # takes three arguments, but here we are just changing h for harvest,
        # while leaving stock & valu fixed. Then Optim knows its trying to change h
        # to find the minimum.
        # The second 2 arguments, 0 & stock are the bounds to search between.
        # (whcih forces harvest to be less than the current stock)
        result = optimize(h -> objective(h, stock, valu), 0.0, stock)
        # Ok hopefully that worked, now store the results...
        optimal_harvest[stock_idx] = result.minimizer
        # Store the negative of the function minimum to make it positive again
        valu_next[stock_idx] = -result.minimum
    end

    # Ok we have updated the value function for one iteration!
    # println("Iteration:")
    println(counter)
    global counter += 1  # Add 1 to the counter

    # Check to see if the value function has converged...
    global converged = check_convergence(valu,valu_next)

    # Update the continuation value
    global valu = valu_next
    # Store the harvest (so we can tell what happened after the fact)
    global harvest = optimal_harvest

end

println("The optimal harvest rule is:")
println(harvest)
# Remember these correspond to the levels of the stock grid...
# So if the current stock is 100, the optimal thing to do is harvest 55.55
