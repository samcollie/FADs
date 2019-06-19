# Load Packages
using Optim
using Interpolations

# Define global constants
const carrying_capacity = 100
const r = 0.8
const discount_factor = 0.9
const convcrit = 1e-6
const ngrid = 100
const stock_grid = range(0.0, carrying_capacity, length = ngrid)

# Define Functions
function stock_next(harvest, stock)
    new_stock = stock .- harvest .+ r .* stock .* (1 .- stock ./ carrying_capacity)
    new_stock
end

function profit(harvest)
    harvest # Placeholder
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
    valu_interp = LinearInterpolation(stock_grid, valu)
    for idx in 1:ngrid
        stock = stock_grid[idx]
        valu_next[idx] = optimal_harvest(stock, valu_interp)
    end
    valu_next
end

function valu_iteration()
    valu = zeros(ngrid)
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

# Run once to compile
valu_iteration()
# Time it & check allocations
function test()
    @time valu_iteration()
end
println(test())
