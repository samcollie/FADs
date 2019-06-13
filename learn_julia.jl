# Goal: Find the optimal number and placement of FADs in a simple fishing ground
#       This is the "simplest possible" model.

# Notes: Make sure you only read the newest version of the Julia documentation...
# https://docs.julialang.org/en/v1/
# A lot of the stuff online pertains to beta versions (prior to 1.0) that
# doesn't apply anymore. Just search the docs in the link above instead.

# Step 0: Load Packages
using LinearAlgebra

# Step 1: Initialize a model fishing ground
carrying_capacity = 100
r = 0.8     # A parameter for the Gordon-Schaefer logistic growth function
dim = 2     # The number of patches on one edge of the [square] fishing ground
npatches = dim^2    # Total number of patches

# Gordon-Schaefer Stock Growth Function
# Note: The '.*' and '.+' is used to add/multiply a scalar and a vector (same as matlab)
function stock_growth(stock, harvest)
    stock - harvest + r * stock .* (1 .- stock/carrying_capacity)
end

# Add dispersion. Note the '*' is a dot product (linear algebra)
function stock_next(stock,harvest,dispersal)
    dispersal * stock_growth(stock,harvest)
end


# OK lets test it out.
# Start with the stock at 1/2 carrying capacity and an example dispersion matrix.
# Then harvest 1/2 of the stock in one patch every period for 100 periods

# Start the stock out at 50% the of carrying capacity.
test_stock = (1/2)*carrying_capacity*ones(npatches)

# Create an example dispersion matrix.
# This is 50% infinite dispersion (the stock in each patch spreads to every other)
# and 50% no dispersion (the stock stays in the patch).
# You can type 'I' to get an identity matrix of any size! Weird.
test_dispersal = (ones(npatches,npatches)/npatches + I)/2


# Now I will loop through 100 time periods, harvesting half of the stock
# in patch 1 in every period.

# For loops turn out to be a bit different in Julia as well, each time around
# it forgets the variables, unless they are defined as globals

println("Test 1: Loop 100 Times")

for t = 1:100
    # Define the harvest vector
    test_harvest = zeros(npatches)
    test_harvest[1] = test_stock[1]/2

    # Update the stock using that harvest
    global test_stock = stock_next(test_stock, test_harvest, test_dispersal)

    # Print to see what happens
    println(test_stock)

end

# Instead of looping 100 times, I'll use a while loop to stop after convergence

stock = (1/2)*carrying_capacity*ones(npatches)

diff = 10 # something greater than 0

println("\n")
println("Test 2: While")

while diff > 1e-4

    # Harvest 50% of the stock in patch 1
    harvest = zeros(npatches)
    harvest[1] = test_stock[1]/2

    # Get the stock in the next period when harvest is applied
    new_stock = stock_next(stock, harvest, test_dispersal)
    println(new_stock)

    # The SUP-Norm.
    # The largest absolute difference between the old & new stock
    global diff = maximum(abs.(new_stock - stock))

    # After checking for convergence, update the stock.
    global stock = new_stock

end


# Yayy I got the same thing.
# OK gotta clean this up a bunch etc. Maybe make it object oriented
