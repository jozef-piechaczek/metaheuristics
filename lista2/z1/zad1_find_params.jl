println("----RUN----")


"Calculate cost of solution"
function cost(x)
    (x1, x2, x3, x4) = x
    return (1.0 - cos(2.0 * pi * sqrt(x1^2 + x2^2 + x3^2 + x4^2))
        + 0.1 * (x1^2 + x2^2 + x3^2 + x4^2))
end

"Find next solution in neighbourhood"
function neighbour(x, domain, n_mdf)
    next(xi) = max(min((xi + randn() / n_mdf), domain[2]), domain[1])
    return map(next, x)
end

"Simulated annealing"
function annealing(t, domain, n_mdf, t_red, it_to_red, t_init)

    e = MathConstants.e
    amplitude = domain[2] - domain[1]
    # start_point = map(x -> amplitude * rand() - amplitude/2, (0,0,0,0))
    start_point = (-80.3129276212676, -89.2941407812653, -0.4771413735791725, 23.29138787130573)

    c_state = start_point
    c_cost = cost(c_state)
    c_temp = t_init
    start_time = time_ns()
    end_time = start_time + 1e9 * t
    while time_ns() < end_time
        for i = 1:it_to_red
            n_state = neighbour(c_state, domain, n_mdf)
            if cost(n_state) < cost(c_state)
                c_state = n_state
            elseif rand() < e ^ (-((cost(n_state) - cost(c_state)) / c_temp))
                c_state = n_state
            end
        end
        c_temp = c_temp * t_red
    end
    return c_state, c_temp
end

function runf()

    min_cost = 1e10

    domain = (-100.0, 100.0)

    n_mdf = 3
    t_red = 0.8
    it_to_red = 7e3
    t_init = 1

    while true
        n_mdf = rand() * 10
        t_red = 0.5 + (rand() / 2)
        it_to_red = 100 + 10e4 * rand()
        t_init = rand() * 1e5

        q_result, _ = annealing(1, domain, n_mdf, t_red, it_to_red, t_init)
        q_cost = cost(q_result)

        if q_cost < min_cost
            min_cost = q_cost
            println()
            println("cost: ", min_cost)
            println(n_mdf)
            println(t_red)
            println(it_to_red)
            println(t_init)
        end

    end

    result, temp = annealing(1, domain, n_mdf, t_red, it_to_red, t_init)
    println()
    println(result)
    println(cost(result))
    print(temp)

end

runf()
