module Agent
export annealing

mutable struct GridStr
    grid::Array{Int}
    i::Int
    j::Int
end

mutable struct AgentStr # Agent point of view
    steps::Array{Tuple{Int, Int}}
    i::Int
    j::Int
    dir::Char
end

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
function find_cost(solution, grid, i, j)
    cost = 0
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
        if grid[i, j] == 1
            return MAX # Agent walked into wall
        end
        if grid[i, j] == 8
            return cost # Agent walked into exit
        end
    end
    return MAX # Agent haven't walked out
end

##### First solution #####

dirs = ['U', 'R', 'D', 'L']
right(d) = dirs[findfirst(x -> x == d, dirs) % 4 + 1]
left(d) = dirs[(findfirst(x -> x == d, dirs) + 2) % 4 + 1]
rand_dir() = dirs[rand(1:length(dirs))]

"Get tile at given direction"
function get_tile(gs::GridStr, d)
    if d == 'U'
        return gs.grid[gs.i-1,gs.j]
    elseif d == 'R'
        return gs.grid[gs.i,gs.j+1]
    elseif d == 'D'
        return gs.grid[gs.i+1,gs.j]
    elseif d == 'L'
        return gs.grid[gs.i,gs.j-1]
    else
        throw(NotExistingMoveException)
    end
end

"Update structure with given direction"
function update_str(str, d)
    if d == 'U'
        str.i -= 1
    elseif d == 'R'
        str.j += 1
    elseif d == 'D'
        str.i += 1
    elseif d == 'L'
        str.j -= 1
    else
        throw(NotExistingMoveException)
    end
end

"Make step in given direction"
function make_step(gs::GridStr, as::AgentStr, solution)
    if get_tile(gs, as.dir) != 1
        update_str(gs, as.dir)
        update_str(as, as.dir)
        append!(solution, [as.dir])
        append!(as.steps, [(as.i, as.j)])
    end
end

"Make step forward and return true if next step is possible"
function make_step_forward(gs::GridStr, as::AgentStr, solution)
    make_step(gs, as, solution)
    possible = (get_tile(gs, as.dir) != 1)
    return possible
end

"Check if exit is around agent"
function check_exit(gs::GridStr, as::AgentStr, solution)
    for d in dirs
        if get_tile(gs, d) == 8
            as.dir = d
            make_step(gs, as, solution)
            return true
        end
    end
    return false
end

"Make step and have wall on your left side"
function make_step_wall(gs::GridStr, as::AgentStr, solution)
    if get_tile(gs, left(as.dir)) != 1 # no wall on the left
        as.dir = left(as.dir)
    else
        if get_tile(gs, as.dir) == 1
            as.dir = right(as.dir)
        end
    end
    make_step(gs, as, solution)
end

"Check if not walking in loop"
function check_loops(gs::GridStr, as::AgentStr, solution)
    num = length(findall(x -> x == as.steps[length(as.steps)], as.steps))
    if num > 2
        resolve_loop(gs, as, solution)
    end
end

"Change direction if walking in loop"
function resolve_loop(gs::GridStr, as::AgentStr, solution)
    as.dir = rand_dir()
    as.steps = []
end

"Find start solution"
function find_start_solution(grid, n, m, up_i, up_j)
    gs = GridStr(grid, up_i, up_j)
    as = AgentStr([], 0, 0, 'U')
    solution = []

    while true
        if check_exit(gs, as, solution) return solution end
        if !make_step_forward(gs, as, solution) break end
    end
    as.dir = 'R'
    while true
        if check_exit(gs, as, solution) return solution end
        make_step_wall(gs, as, solution)
        check_loops(gs, as, solution)
    end

    return solution
end

##### Neighbour #####

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

"Add some steps to solution"
function add_rand_steps(solution, add_param, n, m)
    for i = 1:Int(floor(abs(randn() * ((n + m) / add_param))))
        insert!(solution, rand(1:length(solution)), rand_dir())
    end
    return solution
end

"Adjust neighbour"
function adjust_neighbour(solution, add_param, n, m)
    solution = rmv_unnecessary_moves(solution)
    solution = rmv_loops(solution)
    solution = add_rand_steps(solution, add_param, n, m)
return solution
end

"Find neighbour"
function find_neighbour(solution, add_param, n, m)
    r1 = rand(1:length(solution))
    r2 = rand(1:length(solution))
    solution[r1], solution[r2] = solution[r2], solution[r1]
    return adjust_neighbour(solution, add_param, n, m)
end

##### Main code #####

"Remove part of solution after exiting grid"
function trim(solution, grid, agent_i, agent_j)
    idx = 0
    for s in solution
        if s == 'U'
            agent_i -= 1
        elseif s == 'R'
            agent_j += 1
        elseif s == 'D'
            agent_i += 1
        elseif s == 'L'
            agent_j -= 1
        end
        idx += 1
        if grid[agent_i,agent_j] == 1
            return solution
        end
        if grid[agent_i,agent_j] == 8
            return solution[1:idx]
        end
    end
    return solution
end

"Simulated annealing"
function annealing(t, n, m, grid, t_red, it_to_red, t_init, add_param)
    agent_i, agent_j = find_agent_coords(grid, n, m)
    cost(x) = find_cost(x, grid, agent_i, agent_j)

    c_state = find_start_solution(grid, n, m, agent_i, agent_j)
    c_cost  = cost(c_state)

    c_temp  = t_init
    start_time = time_ns()
    end_time = start_time + 1e9 * t
    while time_ns() < end_time
        for i = 1:it_to_red
            n_state = find_neighbour(deepcopy(c_state), add_param, n, m)
            if cost(n_state) < MAX
                if cost(n_state) < cost(c_state)
                    n_state = trim(n_state, grid, agent_i, agent_j)
                    c_state = n_state
                elseif rand() < (MathConstants.e ^
                        (-((cost(n_state) - cost(c_state)) / c_temp)))
                    n_state = trim(n_state, grid, agent_i, agent_j)
                    c_state = n_state
                end
            end
        end
        c_temp *= t_red
    end
    return cost(c_state), c_state
end

end
