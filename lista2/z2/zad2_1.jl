using LinearAlgebra

vals = [0, 32, 64, 128, 160, 192, 223, 255]

function read_args()
    args = map(x -> string(x), ARGS)
    file_in = args[1]
    file_out = args[2]
    file_err = args[3]
    return file_in, file_out, file_err
end

function read_matrix(file_in)
    matrix, f_line, lines = [], [], []
    f_line = []
    open(file_in) do file
        f_line = split(readline(file), " ")
        lines = readlines(file)
    end
    params = map(x -> parse(Int, x), f_line)
    println(params)
    t, n, m, k = params
    for i = 1:length(lines)
        if !(isempty(strip(lines[i])))
            matrix = append!(matrix, [map(l -> parse(Int, l), split(lines[i], " "))])
        end
    end
    return t, n, m, k, matrix
end

function write_matrix(file_out, file_err, length, matrix)
    open(file_out, "w") do file
        write(file, "$(length)\n")
    end
    open(file_err, "w") do file
        map(row -> write(file, string(reduce((x, y) -> "$x $y", row), "\n")),
            matrix)
    end
end

function dist(n, m, mx1, mx2)
    result = 0
    for i = 1:n
        for j = 1:m
            result += (mx1[i,j] - mx2[i,j])^2
        end
    end
    result = result / (n * m)
    return result
end

function start_matrix(n, m, k)
    rand_val() = vals[rand(1:length(vals))]
    mx = Matrix{Int}(undef, n, m)
    ib_max = (div(n, k))
    jb_max = (div(m, k))
    mx_map = Array{Array{Int}}(undef, ib_max, jb_max) # info about blocks
    # it looks bad, but it is O(n * m)
    for ib in 1:ib_max # horizontal block
        for jb in 1:jb_max # vertical block
            val = rand_val()
            i_min = (1 + k * (ib - 1))
            j_min = (1 + k * (jb - 1))
            i_max = if (ib == ib_max) n else (k * ib) end
            j_max = if (jb == jb_max) m else (k * jb) end
            mx_map[ib,jb] = [(i_max - i_min) + 1, (j_max - j_min) + 1]
            for i in i_min:i_max # iterate over block
                for j in j_min:j_max
                    mx[i,j] = val
                end
            end
        end
    end
    return mx, mx_map
end

function get_block_starti(blocks, bi, bj)
    start_i = 1
    for i in 1:(bi - 1)
        start_i += blocks[i,bj][1]
    end
    return start_i
end

function get_block_startj(blocks, bi, bj)
    start_j = 1
    for j in 1:(bj - 1)
        start_j += blocks[bi,j][2]
    end
    return start_j
end


function change_intensivity(mx, blocks)
    max_i, max_j = size(blocks)
    block_i = rand(1:max_i)
    block_j = rand(1:max_j)
    block = blocks[block_i, block_j]
    start_i = get_block_starti(blocks, block_i, block_j)
    start_j = get_block_startj(blocks, block_i, block_j)
    new_val = vals[rand(1:length(vals))]
    for i in start_i:(start_i +  block[1] - 1)
        for j in start_j:(start_j + block[2] - 1)
            mx[i,j] = new_val
        end
    end
    return mx, blocks
end

function resize_block(mx, blocks)

    return mx, blocks
end

function swap_blocks(mx, blocks)

    return mx, blocks
end

function neighbour(mx, blocks)
    if rand() < 0.5 mx, blocks = change_intensivity(mx, blocks) end
    if rand() < 0.5 mx, blocks = resize_block(mx, blocks) end
    if rand() < 0.5 mx, blocks = swap_blocks(mx, blocks) end
    return mx, blocks
end

function annealing(t, n, m, k, mx, t_red, it_to_red, t_init)
    cost(mx2) = dist(n, m, mx, mx2)

    c_state, c_block = start_matrix(n, m, k)
    c_cost = cost(c_state)
    c_temp = t_init
    start_time = time_ns()
    end_time = start_time + 1e9 * t
    while time_ns() < end_time
        for i = 1:it_to_red
            n_state = neighbour(c_state)
            if cost(n_state) < cost(c_state)
                c_state = n_state
            elseif rand() < e ^ (-((cost(n_state) - cost(c_state)) / c_temp))
                c_state = n_state
            end
        end
        c_temp *= t_red
    end
    println(cost(mx), " -> ", cost(c_state))
    return cost(c_state), c_state
end

function main()
    file_in, file_out, file_err = read_args()
    t, n, m, k, mx = read_matrix(file_in)
    length, new_mx = annealing(t, n, m, k, mx)
    write_matrix(file_out, file_err, length, new_mx)
end

for i in 1:50
    m1, m1_map = start_matrix(11,11,2)
    m1a, m1a_map = change_intensivity(deepcopy(m1), m1_map)
    println()
end
# println(m1_map)
# println(m1)
# m2, m2_map = start_matrix(7,7,2)
# println(m2)
# println(m2_map)
# println(dist(7, 7, m1, m2))