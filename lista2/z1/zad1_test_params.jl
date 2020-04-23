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
    start_point = map(x -> amplitude * rand() - amplitude/2, (0,0,0,0))

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

    domain = (-100.0, 100.0)
    no_of_tests = 100

    props = [
        # (3.3833515330377772, 0.8031791525320104, 31433.054925332137, 35980.87162166312),
        # (4.6606861136921935, 0.6215823648999437, 2130.0712525579856, 2092.800102712955),
        (3.5445250988232058, 0.7101914737586892, 4369.694405699309,  73746.95150410155), #
        # (4.597477375214218,  0.5693480666810733, 12057.738666604011, 63901.65473722001),
        (3.1471035773100686, 0.7738283075871519, 26919.112412245526, 76719.27203934427),
        # (3.7955170688155526, 0.6979953759271317, 5724.080106660445,  41507.54857662924),
        # (3.672448938948316,  0.6561228437973231, 24004.452702140967, 5820.357253987551),
        (3.88576754457554,   0.6105934368510667, 17861.600001929433, 90098.18527053486),
        (3.594642389840954,  0.5053969586747237, 19388.98944459414,  57637.291737775566),
        (3.3833515330377772, 0.8031791525320104, 31433.054925332137, 35980.87162166312),
        (3.8773526344097897, 0.7881354467000018, 6623.434163256869,  53680.21518298294)

    ]

    for idx = 1:length(props)
        (n_mdf, t_red, it_to_red, t_init) = props[idx]
        sum_costs = 0
        for j = 1:no_of_tests
            q_result, _ = annealing(1, domain, n_mdf, t_red, it_to_red, t_init)
            sum_costs += cost(q_result)
        end
        println("IDX: ", idx)
        println(sum_costs / no_of_tests)

    end

end

runf()
