module ACS_RLF
export acs_t, acs_it

# using SparseArrays
using LightGraphs
using Random
using StatsBase

mutable struct AntStr
    # Coloring of graph in given step
    solution::Array{Int}
    # Color used in given moment
    color::Int
    # Set of uncolored vertices in given iteration
    UC::Set{Int}
    # Set of uncolored vertices in given iteration
    U::Set{Int}
    # Set (initially empty) of uncolored vertices with at least one neighbor in C
    W::Set{Int}
    # Path of ant in given iteration
    path::Array{Int}
    # Current vertex of ant
    current::Int
end

mutable struct StateStr
    # Matrix of pheromones
    ph::Array{Float64,2}
    # Best solution yet
    best_sol::Array{Int}
    # Best cost yet
    best_cost::Int
    # Path of ant that created best solution
    best_path::Array{Int}
end

mutable struct ParamStr
    # colony size, D = [1, Inf]
    ant_count::Int
    # probability of chosing best vertex in transition, D = [0, 1]
    q0::Float64
    # importance of pheromone trail, D = [0, 1]
    alfa::Float64
    # importance of DSAT, D = [0, 1]
    beta::Float64
    # pheromone trail persistence, D = [0, 1]
    p::Float64
    # number of iteration to evaporate, D = [1, Inf]
    iter_to_evaporate
    # number of iteration to rerun, D = [1, Inf]
    iter_ro_reset
    # declay of pheromone, D = [0, 1]
    eps::Float64
end

"Cost of solution, defined as number of colors used"
cost(solution) = maximum(solution)

"Quality of solution"
quality(solution) = 1 / cost(solution)

function create_pheromone_matrix(graph)
    v = nv(graph)
    ph = ones(v, v)
    for edge in edges(graph)
        ph[edge.src, edge.dst] = 0
        ph[edge.dst, edge.src] = 0
    end
    return ph
end

"Initialize state"
function init_state(graph::SimpleGraph)
    state = StateStr(create_pheromone_matrix(graph), [], typemax(Int64), [])
    return state
end

function max_degree_idx(graph::SimpleGraph) # TODO ???
    max_idx = -1
    max_value = -1
    for (idx, deg) in enumerate(degree(graph))
        if deg > max_value
            max_idx = idx
            max_value = deg
        end
    end
    return max_idx
end

"Create ants with default values"
function init_ants(params::ParamStr, graph::SimpleGraph)
    vcount = nv(graph)
    # degrees = collect(enumerate(degree(graph)))
    # sort!(degrees, by = x -> x[2])
    ants = []
    for i in 1:params.ant_count
        current = rand(1:vcount)
        # current = pop!(degrees)[1]
        color = 1
        solution = zeros(vcount)
        solution[current] = color
        UC::Set = Set(deleteat!(collect(vertices(graph)), current))
        W::Set = Set(neighbors(graph, current))
        U::Set = setdiff(UC, W)
        path = [current]
        push!(ants, AntStr(solution, color, UC, U, W, path, current))
    end
    return ants
end

eta_w(vn, ant, graph) = count(vw -> has_edge(graph, vn, vw), ant.W)
eta_u(vn, ant, graph) = count(vu -> has_edge(graph, vn, vu), ant.U)

"Choose next vertex to color"
function choose_next_vertex(ant, params, state, graph)
    max_vertex = -1
    max_value  = -1
    v_dict = Dict()
    v_curr = ant.current
    if isempty(ant.U)
        for v_uc in ant.UC
            v_dict[v_uc] = state.ph[v_curr,v_uc] ^ params.alfa +
                           eta_u(v_uc, ant, graph) ^ params.beta
            if v_dict[v_uc] > max_value
                max_vertex = v_uc
                max_value  = v_dict[v_uc]
            end
        end
    else
        for v_u in ant.U
            v_dict[v_u] = state.ph[v_curr,v_u] ^ params.alfa +
                              eta_w(v_u, ant, graph) ^ params.beta
            if v_dict[v_u] > max_value
                max_vertex = v_u
                max_value  = v_dict[v_u]
            end
        end
    end
    if rand() < params.q0
        return max_vertex
    else
        sum_weight = sum(values(v_dict))
        items = []
        weight_list::Array{Float64} = []
        for (k, v) in v_dict
            push!(items, k)
            push!(weight_list, (v / sum_weight))
        end
        return sample(items, StatsBase.Weights(weight_list))
    end
end

"Color given vertex"
function color_vertex(vnext, ant, graph)
    if isempty(ant.U)
        # Update color
        ant.color += 1
        # Update uncolored vertices in given iteration
        ant.U = deepcopy(ant.UC)
    end
    # Color vertex
    ant.solution[vnext] = ant.color
    # Remove vertex from uncolored vertices
    delete!(ant.UC, vnext)
    # Find neighborhood of vnext in U
    vnext_neighb = filter(x -> has_edge(graph, vnext, x), ant.U)
    # Add neighborhood to W
    union!(ant.W, vnext_neighb)
    # Remove vnext and neighborhood from U
    push!(vnext_neighb, vnext)
    setdiff!(ant.U, vnext_neighb)
end

"Update pheromone trail"
function stage_by_stage_trail_update(v_next, ant, params, state, graph)
    v_curr = ant.current
    if !has_edge(graph, v_curr, v_next)
        new_trail = (1 - params.p) *            # evaporation coefficient
                    state.ph[v_curr,v_next] +   # current trail
                    params.p                    # new pheromones
        state.ph[v_curr,v_next] = new_trail
        state.ph[v_next,v_curr] = new_trail
    end
end

function make_step(vnext, ant)
    ant.current = vnext
    push!(ant.path, vnext)
end

"Return true if all ants found solution"
function all_ants_found_solution(ants)
    for ant in ants
        if length(ant.UC) > 0
            return false
        end
    end
    return true
end

"Update best solution"
function get_best_solution(ants, state)
    for ant in ants
        if ant.color < state.best_cost
            state.best_cost = ant.color
            state.best_sol  = ant.solution
            state.best_path = ant.path
            # println(state.best_cost)
        end
    end
end

function evaporation(state, params)
    state.ph = map(trail -> (1 - params.p) * trail, state.ph)
end

function offline_deamon_trail_update(ants, params, state, graph)
    for i in 1:(length(state.best_path)-1)
        vi = state.best_path[i]
        vj = state.best_path[i+1]
        if !has_edge(graph, vi, vj)
            state.ph[vi,vj] = (params.eps) * state.ph[vi,vj] + 1
            # state.ph[vi,vj] += params.eps
            state.ph[vj,vi] = (params.eps) * state.ph[vj,vi] + 1
            # state.ph[vj,vi] += params.eps
        end
    end
end


function acs_t(t, params::ParamStr, graph::SimpleGraph)
    # println("dummy")
    state = init_state(graph)
    ants = init_ants(params, graph)
    start_time = time_ns()
    end_time = start_time + 1e9 * t
    old_best = typemax(Int64)
    old_best_count = 0
    while time_ns() < end_time
        while !all_ants_found_solution(ants)
            for ant in ants
                if length(ant.UC) > 0 # if there are still vertices to visit
                    vnext = choose_next_vertex(ant, params, state, graph)
                    color_vertex(vnext, ant, graph)
                    stage_by_stage_trail_update(vnext, ant, params, state, graph)
                    make_step(vnext, ant)
                end
            end
        end
        get_best_solution(ants, state)
        if (state.best_cost == old_best)
            old_best_count += 1
        else
            old_best_count = 0
            old_best = state.best_cost
        end
        if old_best_count > params.iter_to_evaporate
            old_best_count = 0
            evaporation(state, params)
        end
        if old_best_count > params.iter_ro_reset
            old_best_count = 0
            # println("reset")
            state.ph = create_pheromone_matrix(graph)
        end
        offline_deamon_trail_update(ants, params, state, graph)
        ants = init_ants(params, graph)
      # print(9)
    end
    # println(state.best_cost)
    # println(state.ph)
end


function acs_it(it, params::ParamStr, graph::SimpleGraph)
    # println("dummy")
    state = init_state(graph)
    ants = init_ants(params, graph)
    old_best = typemax(Int64)
    old_best_count = 0
    for i = 1:it
        while !all_ants_found_solution(ants)
            for ant in ants
                if length(ant.UC) > 0 # if there are still vertices to visit
                    vnext = choose_next_vertex(ant, params, state, graph)
                    color_vertex(vnext, ant, graph)
                    stage_by_stage_trail_update(vnext, ant, params, state, graph)
                    make_step(vnext, ant)
                end
            end
        end
        get_best_solution(ants, state)
        if (state.best_cost == old_best)
            old_best_count += 1
        else
            old_best_count = 0
            old_best = state.best_cost
        end
        if old_best_count > params.iter_to_evaporate
            old_best_count = 0
            evaporation(state, params)
        end
        if old_best_count > params.iter_ro_reset
            old_best_count = 0
            # println("reset")
            state.ph = create_pheromone_matrix(graph)
        end
        offline_deamon_trail_update(ants, params, state, graph)
        ants = init_ants(params, graph)
      # print(9)
    end
    # # println(state.best_cost)
    # # println(state.ph)
    return state.best_cost
end

# t = 60
# params = ParamStr(40, 0.5, 2.0, 4.0, 0.5, 7, 25, 0.35)
# graph = loadgraph("/home/dzazef/repos/metaheuristics/referat/graphs/65_r250_5.lg")
# # graph = loadgraph("/home/dzazef/repos/metaheuristics/referat/graphs/44_dsjc125.lg")
# # graph = loadgraph("/home/dzazef/repos/metaheuristics/referat/graphs/28_flat300_28_0.lg")
# # graph = loadgraph("/home/dzazef/repos/metaheuristics/referat/graphs/3_3part9vert.lg")
# # println("start")
# acs_t(t, params, graph)

greedy_color
end
