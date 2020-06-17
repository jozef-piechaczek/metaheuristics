module ACS_DSAT
export acs_t, acs_it

using SparseArrays
using LightGraphs
using Random
using StatsBase

mutable struct AntStr
    # coloring of graph in given step
    local_solution::Array{Int}
    V::Array{Int}
    current::Int
    # color used in given moment
    color::Int
    # path of ant in given iteration
    path::Array{Int}
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


"Create ants with default values"
function init_ants(params::ParamStr, graph::SimpleGraph)
    vcount = nv(graph)
    # degrees = collect(enumerate(degree(graph)))
    # sort!(degrees, by = x -> x[2])
    ants = []
    for i in 1:params.ant_count
        # current = pop!(degrees)[1]
        current = rand(1:vcount)
        color = 1
        local_solution = zeros(vcount)
        local_solution[current] = color
        V = deleteat!(collect(vertices(graph)), current)
        path = [current]
        push!(ants, AntStr(local_solution, V, current, color, path))
    end
    return ants
end

"Calculate degree of saturation of given vertex"
function dsat(v, solution, graph)
    colors = Set{Int}(0)
    for vn in neighbors(graph, v)
        push!(colors, solution[vn])
    end
    return length(colors) - 1
end

"Choose next vertex to color"
function choose_next_vertex(ant, params, state, graph)
    max_vertex = -1
    max_value  = -1
    v_dict = Dict()
    v_curr = ant.current
    for v_neigh in ant.V
        v_dict[v_neigh] = state.ph[v_curr,v_neigh] ^ params.alfa +
                          dsat(v_neigh, ant.local_solution, graph) ^ params.beta
        if v_dict[v_neigh] > max_value
            max_vertex = v_neigh
            max_value  = v_dict[v_neigh]
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
    used_colors = Set(0)
    for vn in neighbors(graph, vnext)
        push!(used_colors, ant.local_solution[vn])
    end
    all_colors = Set(collect(0:ant.color))
    possible_colors = setdiff(all_colors, used_colors)
    if length(possible_colors) == 0
        ant.color += 1
        ant.local_solution[vnext] = ant.color
    else
        ant.local_solution[vnext] = minimum(possible_colors)
    end
end

"Remove vertex from array of vertices to visit"
function update_tabu(vnext, ant)
    deleteat!(ant.V, ant.V.==vnext)
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
        if length(ant.V) > 0
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
            state.best_sol  = ant.local_solution
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
            state.ph[vj,vi] = (params.eps) * state.ph[vj,vi] + 1
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
                if length(ant.V) > 0 # if there are still vertices to visit
                    vnext = choose_next_vertex(ant, params, state, graph)
                    color_vertex(vnext, ant, graph)
                    update_tabu(vnext, ant)
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
                if length(ant.V) > 0 # if there are still vertices to visit
                    vnext = choose_next_vertex(ant, params, state, graph)
                    color_vertex(vnext, ant, graph)
                    update_tabu(vnext, ant)
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

# t = 1
# params = ParamStr(40, 0.5, 2.0, 4.0, 0.5, 15, 50, 0.35)
# graph = loadgraph("/home/dzazef/repos/metaheuristics/referat/graphs/65_r250_5.lg")
# # graph = loadgraph("/home/dzazef/repos/metaheuristics/referat/graphs/44_dsjc125.lg")
# # graph = loadgraph("/home/dzazef/repos/metaheuristics/referat/graphs/28_flat300_28_0.lg")
# # graph = loadgraph("/home/dzazef/repos/metaheuristics/referat/graphs/3_3part9vert.lg")
# # println("start")
# acs_it(t, params, graph)
end
