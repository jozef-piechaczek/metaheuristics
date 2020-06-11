include("./agent.jl")
using .Agent

function read_args()
    args = map(string, ARGS)
    file_in = args[1]
    file_out = args[2]
    file_err = args[3]
    return file_in, file_out, file_err
end

function read_grid(file_in)
    f_line, lines = nothing, nothing
    solutions = []
    open(file_in) do file
        f_line = split(strip(readline(file)), " ")
        lines = readlines(file)
    end
    t, n, m, s, p = map(x -> parse(Int, x), f_line)
    grid = Array{Int}(undef, n, m)
    for i = 1:n
        line = strip(lines[i])
        for j = 1:m
            grid[i,j] = parse(Int, line[j])
        end
    end
    for i = (n+1):(n+s)
        line = strip(lines[i])
        push!(solutions, map(x -> first(x), split(line, "")))
    end
    return t, n, m, s, p, grid, solutions
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
    file_in, file_out, file_err = read_args()
    t, n, m, s, p, grid, solutions = read_grid(file_in)
    cost, solution = run_ga(t, n, m, s, p, grid, solutions, [])
    write_result(file_out, file_err, cost, solution)
end

main()
