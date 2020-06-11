include("./ga.jl")
using .Genetics

g_dict_path = "./dict.txt"
g_psize = 8 # must be even
g_select = 0.94 # [0.0, 1.0]
g_select_t = 0.8# [0.0, 1.0]
g_mutate = 1.0# [0.0, 1.0]
g_mutate_letter = 0.01# [0.0, 1.0]
g_survive = 0.08# [0.0, 1.0]
g_repeat_to_reset = 900

"Read arguments"
function read_args()
    args = map(string, ARGS)
    file_in = args[1]
    file_out = args[2]
    file_err = args[3]
    return file_in, file_out, file_err
end


"Read and parse file with args"
function get_run_args(file_in)
    letters, words::Array{String} = Dict(), []
    letters_vec::Array{Char} = []
    f_line, lines = [], []
    # Read lines from file
    open(file_in) do file
        f_line = split(strip(readline(file)), " ")
        lines = map(x -> strip(x), readlines(file))
    end
    # Parse first line
    t, n, s = map(x -> parse(Int, x), f_line)
    # Parse letters
    for i = 1:n
        c_line = split(lines[i], " ")
        c_letter = first(c_line[1])
        c_value = parse(Int, c_line[2])

        push!(letters_vec, c_letter)
        if haskey(letters, c_letter)
            letters[c_letter].count += 1
        else
            letters[c_letter] = LetterInfo(c_value, 1)
        end
    end
    # Parse words
    words = lines[(n+1):(n+s)]
    return t, n, s, letters, letters_vec, words
end


"Read dictionary"
function get_dict(dict_path)
    lines::Array{String} = []
    open(dict_path) do file
        lines = readlines(file)
    end
    return lines
end

"Write result to file"
function write_result(file_out, file_err, score, word)
    open(file_out, "w") do file
        write(file, "$(score)")
    end
    open(file_err, "w") do file
        write(file, "$(word)")
    end
end


function main()
    file_in, file_out, file_err = read_args()
    params = [g_psize, g_select_t, g_mutate, g_mutate_letter, g_survive, g_repeat_to_reset]
    t, n, s, letters, letters_vec, words = get_run_args(file_in)
    dict = get_dict(g_dict_path)
    score, word = Genetics.run_ga(t, n, s, letters, letters_vec, words, dict, params)
    write_result(file_out, file_err, score, word)
end

main()
