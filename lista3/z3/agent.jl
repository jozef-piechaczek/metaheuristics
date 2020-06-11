module Agent
export run_ga

using Random

mutable struct GridStr
    grid::Array{Int}
    i::Int
    j::Int
end

mutable struct StateStr
    population
    best_cost
    best_sol
end

struct ParamStr # Agent point of view
    n
    m
    s
    p
    grid
    solutions
    i
    j
end

random_select_f = 0.3 # 0% to (random_select_f*100)% parents randomly selected
mutate_f = 0.12
compl_mutate_f = 0.03
repeat_to_reset_f = 500

struct NotExistingMoveException <: Exception end
struct AgentDoesNotExistsException <: Exception end
MAX = typemax(Int)

"Find agent location (agent does not know it)"
function find_agent_coords(grid, n, m)
    for i = 1:n
        for j = 1:m
            if grid[i,j] == 5
                return i, j
            end
        end
    end
    throw(AgentDoesNotExistsException)
    return -1, -1
end


"Find cost of solution"
function find_cost(solution, pr::ParamStr, sr::StateStr)
    cost = 0
    i = pr.i
    j = pr.j
    for s in solution
        cost += 1
        if s == 'U'
            i -= 1
        elseif s == 'D'
            i += 1
        elseif s == 'L'
            j -= 1
        elseif s == 'R'
            j += 1
        else
            throw(NotExistingMoveException)
        end
        if pr.grid[i, j] == 1
            return MAX # Agent walked into wall
        end
        if pr.grid[i, j] == 8
            if cost < sr.best_cost
                sr.best_cost = cost
                sr.best_sol = solution[1:min(length(solution), cost)]
            end
            return cost # Agent walked into exit
        end
    end
    return MAX # Agent haven't walked out
end

"Remove loops"
function rmv_loops(solution)
    i, j = 0, 0
    steps = []
    for s in solution
        if s == 'U'
            i -= 1
        elseif s == 'R'
            j += 1
        elseif s == 'D'
            i += 1
        elseif s == 'L'
            j -= 1
        end
        append!(steps, [(i,j)])
    end
    result = []
    for idx_b = 1:length(steps)
        idx_e = findlast(x -> x == steps[idx_b], steps)
        if idx_b != idx_e
            append!(result, solution[1:idx_b])
            append!(result, solution[(idx_e+1):length(solution)])
            return result
        end
    end
    return solution
end

"Remove unnecessary moves"
function rmv_unnecessary_moves(solution)
    idx = 1
    while idx < length(solution)
        if (solution[idx] == 'U' && solution[idx + 1] == 'D'
                || solution[idx] == 'D' && solution[idx + 1] == 'U'
                || solution[idx] == 'L' && solution[idx + 1] == 'R'
                || solution[idx] == 'R' && solution[idx + 1] == 'L')
            deleteat!(solution, idx)
            deleteat!(solution, idx)
            idx -= 1
        end
        idx += 1
    end
    return solution
end

"Replace empty solution with random one"
check_if_empty(solution, pr) = length(solution) == 0 ? rand_solution(pr, false) : solution

dirs = ['U', 'R', 'D', 'L']
rand_dir() = dirs[rand(1:length(dirs))]

"Create random solution"
function rand_solution(params::ParamStr, optim)
    solution = []
    for x in 1:Int(round((0.5 + rand()) * (params.n + params.m)))
        push!(solution, rand_dir())
    end
    if optim
        rmv_unnecessary_moves(solution)
        rmv_loops(solution)
    end
    return solution
end

"Create first population"
function create_population(state::StateStr, params::ParamStr)
    for sol in params.solutions
        sol_with_cost = (sol, find_cost(sol, params, state))
        push!(state.population, sol_with_cost)
    end

    for x in (params.s+1):(params.p)
        sol = rand_solution(params, true)
        sol_with_cost = (sol, find_cost(sol, params, state))
        push!(state.population, sol_with_cost)
    end
end


function selection(state, params)
    needed = Int(round(params.p / 2))
    needed += needed % 2
    selected = state.population[1:needed]
    replace_count = Int(round(rand() * random_select_f * params.p))
    for i = 1:replace_count
        selected[max(1, Int(floor(rand() * needed)))] =
            state.population[max(1, Int(floor(rand() * params.p)))]
    end
    return shuffle(selected)
end

"Single pair reproduction"
function s_reproduct(parent1, parent2)
    lp1 = length(parent1)
    lp2 = length(parent2)
    point = Int(max(1, round(rand() * (lp1 - 1))))
    child1, child2 = "", ""
    if point > lp2
        child1 = parent1[1:point]
        child2 = append!(parent2, parent1[(point+1):lp1])
    else
        child1 = append!(parent1[1:point], parent2[(point+1):lp2])
        child2 = append!(parent2[1:point], parent1[(point+1):lp1])
    end
    return child1, child2
end


function reproduction(selected, state, params)
    reproducted = []
    for i in 1:2:length(selected)
        ch1, ch2 = s_reproduct(selected[i], selected[i+1])
        push!(reproducted, ch1)
        push!(reproducted, ch2)
    end
    return reproducted
end

"Mutate single solution"
function s_mutate(solution, pr)
    if rand() < compl_mutate_f
        return rand_solution(pr, true)
    end
    for i in 1:length(solution)
        if rand() < mutate_f
            solution[i] = rand_dir()
        end
    end
    return solution
end

"Mutate population"
mutate(reproducted, pr) = map(x -> s_mutate(x, pr), reproducted)

"Create new population"
function next_population(state::StateStr, params::ParamStr)

    # sort population
    sort!(state.population, by = x -> x[2])
    # select population to reproduct
    selected = selection(state, params)
    # replace empty solutions with random
    selected_no_empty = map(x -> check_if_empty(x[1], params), selected)
    # reproduction
    reproducted = reproduction(selected_no_empty, state, params)
    # mutation
    mutated = mutate(reproducted, params)
    # removing unnecessary steps
    adjusted = map(x -> rmv_loops(rmv_unnecessary_moves(x)), mutated)
    # cutting out unnecessary steps after stepping on 8
    sols_with_costs = []
    for sol in adjusted
        cost = find_cost(sol, params, state)
        push!(sols_with_costs, (sol[1:min(length(sol), cost)], cost))
    end
    # replace population
    state.population = append!(state.population[1:(params.p - length(sols_with_costs))],
        sols_with_costs)
end

"Run genetic algorithm"
function run_ga(t, n, m, s, p, grid, solutions, params)
    i, j = find_agent_coords(grid, n, m)
    params = ParamStr(n, m, s, p, grid, solutions, i, j)
    state = StateStr([], MAX, [])

    start_time = time_ns()
    end_time = start_time + 1e9 * t

    create_population(state, params)
    old_best = MAX
    old_best_count = 0
    while time_ns() < end_time
        next_population(state, params)
        if (state.best_cost == old_best)
            old_best_count += 1
        else
            old_best_count = 0
            old_best = state.best_cost
        end
        if old_best_count > repeat_to_reset_f
            state.population = []
            create_population(state, params)
            old_best_count = 0
        end
    end

    return state.best_cost, state.best_sol
end


end
