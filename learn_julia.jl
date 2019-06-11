# Goal: Find the optimal number and placement of FADs in a simple fishing ground
#       This is the "simplest possible" model.

# Step 1: Initialize a model fishing ground
carrying_capacity = 100.0
dim = 2     # The number of patches on one edge of the [square] fishing ground
npatches = dim^2    # Total number of patches

# Initialize the stock + harvest at 1/2 & 1/4 of the state space respectively
stock = carrying_capacity/2.0*ones(npatches)         # The fish stock
harvest = carrying_capacity/4.0*ones(npatches)       # Harvest

# An infinitely migratory dispersial matrix
dispersial = (1/npatches)*ones(npatches, npatches)

# Given the current stock & harvest, return the stock in the next period
# This is a Gordon-Schaefer Logistic Growth Model
# To add a scalar to a vector, use .+ (the dot in front is important)
function stock_next(s,h)
    stock_next = s + 0.8 * s .* (1 .- s/carrying_capacity) - h
end
