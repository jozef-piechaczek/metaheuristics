println("----RUN----")

e = MathConstants.e
domain = (-100.0, 100.0)
amplitude = domain[2] - domain[1]
neighbour_mdf = 1
starting_point = map(x -> amplitude * rand() - amplitude/2, (0,0,0,0))
# starting_point = (-1000, 50, 210, 100)
temp_reduction = 0.6
iter_to_red = 1e4
temp_init = 1e2

"Calculate cost of solution"
function cost(x)
    (x1, x2, x3, x4) = x
    return (1.0 - cos(2.0 * pi * sqrt(x1^2 + x2^2 + x3^2 + x4^2))
        + 0.1 * (x1^2 + x2^2 + x3^2 + x4^2))
end

"Find next solution in neighbourhood"
function neighbour(x)
    next(xi) = max(min((xi + randn() / neighbour_mdf), domain[2]), domain[1])
    return map(next, x)
end

"Simulated annealing"
function annealing(t)
    a = 0
    b = 0
    c = 0
    c_state = starting_point
    c_cost = cost(c_state)
    c_temp = temp_init
    start_time = time_ns()
    end_time = start_time + 1e9 * t
    while time_ns() < end_time
        # println(c_state)
        for i = 1:iter_to_red
            c += 1
            n_state = neighbour(c_state)
            if cost(n_state) < cost(c_state)
                a += 1
                c_state = n_state
            elseif rand() < e^((cost(c_state) - cost(n_state)) / c_temp)
                b += 1
                c_state = n_state
            end
        end
        c_temp = c_temp * temp_reduction
    end
    println()
    println(a)
    println(b)
    println(c)
    return c_state, c_temp
end

result, temp = annealing(1)
println(result)
println(cost(starting_point), " -> ", cost(result))
print(temp)
