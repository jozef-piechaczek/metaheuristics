
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
function annealing(t, start_point, n_mdf, t_red, it_to_red, t_init)
    e = MathConstants.e
    domain = (-100.0, 100.0)
    amplitude = domain[2] - domain[1]

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
    return c_state
end

"Read params from file, calculate minimum, and save to file"
function main()
    n_mdf = 3.55
    t_red = 0.72
    it_to_red = 4370.0
    t_init = 73750.0

    args = map(x -> string(x), ARGS)
    file_in = args[1]
    file_out = args[2]
    open(file_in) do file
        params = split(readline(file), " ")
    end
    params = map(x -> parse(Float64, x), params)

    f_result = annealing(params[1], (params[2], params[3], params[4], params[5]),
        n_mdf, t_red, it_to_red, t_init)
    f_cost = cost(f_result)

    open(file_out, "w") do file
        write(file, "$(f_result[1]) $(f_result[2]) $(f_result[3]) $(f_result[4]) $f_cost")
    end
end

main()
