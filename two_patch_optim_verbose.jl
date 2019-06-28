# Attempt at integrating optimization over multiple (2) patches - not done yet...
# Scroll down to the bottom to see how I worked through this & got it going
# I will beautify for future versions...

# Notes. ctrl+j then ctrl+k restarts the kernel
# The find and replace is awesome! changed valu -> value everywhere!

# I don't know why I keep getting a warnig about redefining dispersal... gotta work on that


using LinearAlgebra
using Optim
using Interpolations

# Use constants for all gloabl parameters for speedup
const convcrit = 1e-6
const carrying_capacity = 100
const r = 0.8
const discount_factor = 0.9
const npatches = 2
const ngrid = 3
const stock_grid = range(0.0, carrying_capacity, length = ngrid)
const dispersal = [[0.75 0.25]; [0.25 0.75]]

function stock_growth(harvest, stock)
    # Update the Stock
    new_stock = stock - harvest + r * stock .* (1 .- stock/carrying_capacity)
    # Make sure the new stock is between 0 and 100

end

function stock_next(harvest, stock, dispersal)
    new_stock = dispersal * stock_growth(harvest, stock)
end

# Added 'sum' to the profit function.
# Now profit = sum of harvest in all patches
# Had to add an escape clause for cases where harvest > stock
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

function check_convergence(a,b)
    sup_norm(a,b) < convcrit
end

function bellman(harvest, stock, value_interp)
    current_reward = profit(harvest, stock)
    future_stock = stock_next(harvest, stock, dispersal)
    future_reward = value_interp(future_stock...)
    current_reward + discount_factor*future_reward
end

function optimal_harvest(stock, value_interp)
    objctv = h -> - bellman(h, stock, value_interp)
    # So here, [0, 0] is an initial guess for the optimal harvest.
    # This also tells optimize its a 2d problem
    result = optimize(objctv, [0.0, 0.0])
    #result = optimize(objctv, [0.0, 0.0], stock, [0.0, 0.0], Fminbox())
    # Above is a bounded optimazation method I ended up not using
    -result.minimum
end

# Given the ngrid x ngrid value matrix, return a linear interpolator
# (It returns a function that takes a state (stockA, stockB) as an input
#  and returns a guess of the value function)

function value_interpolator(value)
    csg = collect(stock_grid)
    LinearInterpolation((csg, csg), value, extrapolation_bc = 0.0)
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
        counter += 1  # Add 1 to the counter
    end
    value
end

### Test Test Test....
### Making this thing 2 patches..

harvest = [50.0, 50.0]
stock   = [99.0, 99.0]

sn = stock_next(harvest, stock, dispersal)
# Ok so that works...
# Now onto the harder stuff...

# value & the state space are now npatches*npatches
# So lets say the rows correspond to the stock in Patch A
# and the columns correspond to the stock in Patch B

value = zeros(ngrid, ngrid)
value_interp = LinearInterpolation((collect(stock_grid), collect(stock_grid)), value, extrapolation_bc = 0.0)

# Test that out ...
# SOo let exlain whats going on here. The dots ... is called splatting
# the function value_interp wants 2 argumeents, value_interp(stock_a, stock_b)
# But we have them both in a 2x1 array... so the splat ... makes it happen!
vi = value_interp(stock...)
#println(vi)

b = bellman(harvest, stock, value_interp)
#println(b)
# Great that works now too...

oh = optimal_harvest(stock, value_interp)
# print(oh)

uv = update_value(value)
#println(uv)
# Yay one more major hurdle!

vi = value_iteration()
println(vi)
