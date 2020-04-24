vals = [0, 32, 64, 128, 160, 192, 223, 255]

##### Utils #####

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
    t, n, m, k = params
    matrix = Array{Int}(undef, n, m)
    for i = 1:length(lines)
        line = filter(x -> length(strip(x)) > 0, split(strip(lines[i]), " "))
        for j = 1:length(line)
            matrix[i,j] = parse(Int, line[j])
        end
    end
    return t, n, m, k, matrix
end

function write_matrix(file_out, file_err, length, matrix)
    open(file_out, "w") do file
        write(file, "$(length)\n")
    end
    open(file_err, "w") do file
        n, m = size(matrix)
        for i = 1:n
            for j = 1:m
                write(file, "$(matrix[i,j]) ")
            end
            write(file, "\n")
        end
    end
end

##### Begin main code #####

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
    mx = Array{Int}(undef, n, m)
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

##### Changing intensivity #####

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

##### Resizing block #####

function find_big_blocks(blocks, k)
    possible_blocks = []
    bn, bm = size(blocks)
    for i = 1:bn
        for j = 1:bm
            if blocks[i,j][1] > k || blocks[i,j][2] > k
                append!(possible_blocks, [(i, j)])
            end
        end
    end
    return possible_blocks
end

function find_possible_neighbours(i, j, blocks, k)
    neighbours = []
    n, m = size(blocks)
    if blocks[i,j][1] > k # check verticall
        if (i > 0 && blocks[i,j][2] == blocks[(i-1),j][2]
                && get_block_startj(blocks, i, j) == get_block_startj(blocks, i-1, j))
            append!(neighbours, "U")
        end
        if (i < n && blocks[i,j][2] == blocks[(i+1),j][2]
                && get_block_startj(blocks, i, j) == get_block_startj(blocks, i+1, j))
            append!(neighbours, "D")
        end
    end
    if blocks[i,j][2] > k
        if (j > 0 && blocks[i,j][1] == blocks[i,j-1][1]
                && get_block_starti(blocks, i, j) == get_block_starti(blocks, i, j-1))
            append!(neighbours, "L")
        end
        if (j < m && blocks[i,j][1] == blocks[i,j+1][1]
                && get_block_starti(blocks, i, j) == get_block_starti(blocks, i, j+1))
            append!(neighbours, "R")
        end
    end
    return neighbours
end

function resize(mx, blocks, i0, j0, nb)
    i = get_block_starti(blocks, i0, j0)
    j = get_block_startj(blocks, i0, j0)
    n1, m1 = blocks[i0,j0]
    if nb == "U"
        n2, m2 = blocks[(i0-1),j0]
        for x = j:(j + m1 - 1)
            mx[i,x] = mx[(i-1),x]
        end
        blocks[i0,j0], blocks[(i0-1),j0] = [(n1-1),m1], [(n2+1),m2]
    elseif nb == "D"
        n2, m2 = blocks[(i0+1),j0]
        i = (i + n1 - 1)
        for x = j:(j + m1 - 1)
            mx[i,x] = mx[(i+1),x]
        end
        blocks[i0,j0], blocks[(i0+1),j0] = [(n1-1),m1], [(n2+1),m2]
    elseif nb == "L"
        n2, m2 = blocks[i0,(j0-1)]
        for x = i:(i + n1 - 1)
            mx[x,j] = mx[x,(j-1)]
        end
        blocks[i0,j0], blocks[i0,(j0-1)] = [n1,(m1-1)], [n2,(m2+1)]
    elseif nb == "R"
        n2, m2 = blocks[i0,(j0+1)]
        j = (j + m1 - 1)
        for x = i:(i + n1 - 1)
            mx[x,j] = mx[x,(j+1)]
        end
        blocks[i0,j0], blocks[i0,(j0+1)] = [n1,(m1-1)], [n2,(m2+1)]
    end
end

function resize_block(mx, blocks, n, m, k)
    possible_blocks = find_big_blocks(blocks, k)
    if !isempty(possible_blocks)
        chosen_i, chosen_j = possible_blocks[rand(1:length(possible_blocks))]
        neighbours = find_possible_neighbours(chosen_i, chosen_j, blocks, k)
        if !isempty(neighbours)
            chosen_nb = neighbours[rand(1:length(neighbours))]
            resize(mx, blocks, chosen_i, chosen_j, chosen_nb)
        end
    end
    return mx, blocks
end

##### Main code #####

function neighbour(mx, blocks, n, m, k)
    mx1 = deepcopy(mx)
    mx1, blocks = change_intensivity(mx1, blocks)
    # mx1, blocks = resize_block(mx1, blocks, n, m, k)
    return mx1, blocks
end

function annealing(t, n, m, k, mx, t_red, it_to_red, t_init)
    cost(x) = dist(n, m, mx, x)

    c_state, c_block = start_matrix(n, m, k)
    s_state = deepcopy(c_state)
    c_cost = cost(c_state)
    c_temp = t_init
    start_time = time_ns()
    end_time = start_time + 1e9 * t
    while time_ns() < end_time
        for i = 1:it_to_red
            n_state, n_block = neighbour(c_state, c_block, n, m, k)
            if cost(n_state) < cost(c_state)
                c_state, c_block = n_state, n_block
            elseif rand() < (MathConstants.e ^
                    (-((cost(n_state) - cost(c_state)) / c_temp)))
                c_state, c_block = n_state, n_block
            end
        end
        c_temp *= t_red
    end
    return cost(c_state), c_state
end

function main()
    t_red = 0.72
    it_to_red = 4370.0
    t_init = 73750.0

    file_in, file_out, file_err = read_args()
    t, n, m, k, mx = read_matrix(file_in)
    length, new_mx = annealing(t, n, m, k, mx, t_red, it_to_red, t_init)
    write_matrix(file_out, file_err, length, new_mx)
end

main()
