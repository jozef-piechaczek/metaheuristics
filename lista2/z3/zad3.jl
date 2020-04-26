include("/home/dzazef/repos/metaheuristics/lista2/z3/agent.jl") #TODO
using .Agent

function read_args()
    #TODO: DELETE
    args1 = [
        "/home/dzazef/repos/metaheuristics/lista2/z3/l2z3b.txt",
        "/home/dzazef/repos/metaheuristics/lista2/z3/l2z3b_out.txt",
        "/home/dzazef/repos/metaheuristics/lista2/z3/l2z3b_err.txt"
    ]
    ###################
    args = map(string, ARGS)
    file_in = args[1]
    file_out = args[2]
    file_err = args[3]
    return file_in, file_out, file_err
end

function read_grid(file_in)
    f_line, lines = nothing, nothing
    open(file_in) do file
        f_line = split(strip(readline(file)), " ")
        lines = readlines(file)
    end
    t, n, m = map(x -> parse(Int, x), f_line)
    grid = Array{Int}(undef, n, m)
    for i = 1:n
        line = strip(lines[i])
        for j = 1:m
            grid[i,j] = parse(Int, line[j])
        end
    end
    return t, n, m, grid
end

function write_result(file_out, file_err, steps, solution)
    open(file_out, "w") do file
        write(file, "$(steps)\n")
    end
    solution = string(solution...)
    open(file_err, "w") do file
        write(file, "$(solution)\n")
    end
end

function main()
    t_red = 0.74
    it_to_red = 3980.0
    t_init = 68547.0
    add_param = 5

    file_in, file_out, file_err = read_args()
    t, n, m, grid = read_grid(file_in)
    steps, solution = annealing(t, n, m, grid, t_red, it_to_red, t_init, add_param)
    write_result(file_out, file_err, steps, solution)
end

main()
