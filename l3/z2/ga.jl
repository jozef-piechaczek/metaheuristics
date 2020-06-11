module Genetics

export run_ga
export LetterInfo
using DataStructures
using Random


mutable struct LetterInfo
    value::Int
    count::Int
end

mutable struct StateStr
    best_word::String
    best_cost::Int
    population::Array{Tuple{String, Int}}
end

struct ParamStr
    t::Int
    n::Int
    s::Int
    letters
    letters_vec::Array{Char}
    letters_vec_size::Int
    start_words::Array{String}
    dict::DataStructures.SortedSet{String,Base.Order.ForwardOrdering}
    psize::Int
    select_t::Float64
    mutate::Float64
    mutate_letter::Float64
    survive::Float64
end

"Check if value is in dictionary"
check_in_dict2(word::String, params::ParamStr) =
    haskey(params.dict, word)

"Get cost of word (0 if not acceptable)"
function cost(word::String, params::ParamStr)
    if !check_in_dict2(word, params)
        return 0
    end
    cost = 0
    word_dic = Dict{Char, Int64}()
    for c in word
        if haskey(word_dic, c)
            word_dic[c] += 1
        else
            word_dic[c] = 1
        end
    end
    for (ch, occur) in word_dic
        letter_info = params.letters[ch]
        if occur > letter_info.count
            return 0
        end
        cost += letter_info.value * occur
    end
    return cost
end

"Get cost and update best solution"
function cost_update(word::String, params::ParamStr, state::StateStr)
    c_cost = cost(word, params)
    if c_cost > state.best_cost
        state.best_word = word
        state.best_cost = c_cost
    end
    return c_cost
end

"Generate random acceptable word"
function rand_word(params::ParamStr)
    c_size = Int(round(1.0 + rand() * (params.letters_vec_size - 1)))
    new_vec = shuffle(params.letters_vec)
    return String(new_vec[1:c_size])
end

"Create first population"
function create_population(state::StateStr, params::ParamStr)
    population::Array{Tuple{String, Int}} = []
    for c_word in params.start_words
        c_cost = cost_update(c_word, params, state)
        push!(population, (c_word, c_cost))
    end
    for i in (params.s+1):params.psize
        c_word = rand_word(params)
        c_cost = cost_update(c_word, params, state)
        push!(population, (c_word, c_cost))
    end
    state.population = population
end


function selection(state::StateStr, params::ParamStr)
    needed = Int(round(params.psize / 2))
    return shuffle(state.population)[1:needed]
end

"Single pair reproduction"
function s_reproduct(parent1, parent2, params)
    lp1 = length(parent1)
    lp2 = length(parent2)
    point = Int(max(1, round(rand() * (lp1 - 1))))
    child1, child2 = "", ""
    if point > lp2
        child1 = parent1[1:point]
        child2 = string(parent2, parent1[(point+1):lp1])
    else
        child1 = string(parent1[1:point], parent2[(point+1):lp2])
        child2 = string(parent2[1:point], parent1[(point+1):lp1])
    end
    return child1, child2
end


function reproduction(selected, state::StateStr, params::ParamStr)
    if (length(selected) % 2) != 0
        push!(selected, rand_word(params))
    end
    reproducted = []
    for i in 1:2:length(selected)
        ch1, ch2 = s_reproduct(selected[i][1], selected[i+1][1], params)
        push!(reproducted, ch1)
        push!(reproducted, ch2)
    end
    return reproducted
end

"Single mutation"
function s_mutate(word, params::ParamStr)
    if rand() < params.mutate * 0.5
        return rand_word(params)
    end
    if rand() < params.mutate
        for i in 1:length(word)
            if rand() < params.mutate_letter
                word_arr::Array{Char} = collect(word)
                new_ltr = params.letters_vec[Int(round(1 + rand() *
                    (params.letters_vec_size - 1)))]
                word_arr[i] = new_ltr

                word = String(word_arr)
            end
        end
    end
    return word
end


mutate(reproducted, params::ParamStr) = map(x -> s_mutate(x, params), reproducted)

"Create new population"
function new_population(state::StateStr, params::ParamStr)
    sort!(state.population, by = x -> x[2], rev = true)
    selected = selection(state, params)
    reproducted = reproduction(selected, state, params)
    mutated = mutate(reproducted, params)
    mutated_with_costs = map(x -> (x, cost_update(x, params, state)), mutated)
    alive = params.psize - length(mutated_with_costs)
    state.population = append!(
            state.population[1:alive],
            mutated_with_costs
        )
    unique!(state.population)
    if length(state.population) < params.psize
        for i = 1:(params.psize - length(state.population))
            word = rand_word(params)
            push!(state.population, (word, cost(word, params)))
        end
    end
end

"Run GA"
function run_ga(t::Int, n::Int, s::Int, letters, letters_vec::Array{Char},
            start_words::Array{String}, dict::Array{String}, params)

    psize, select_t, mutate, mutate_letter, survive, repeat_to_reset = params
    start_time = time_ns()
    end_time = start_time + 1e9 * t

    # Data preprocessing: takes about 1s
    sorted_dict = SortedSet(map(x -> lowercase(x), dict))

    # Prepare structures
    state  = StateStr("", 0, [])
    params = ParamStr(t, n, s, letters, letters_vec, size(letters_vec)[1],
        start_words, sorted_dict, psize, select_t, mutate, mutate_letter, survive)

    # Create first population
    create_population(state, params)

    old_best = 0
    old_best_count = 0
    while time_ns() < end_time
        new_population(state, params)
        if (state.best_cost == old_best)
            old_best_count += 1
        else
            old_best_count = 0
            old_best = state.best_cost
        end
        if old_best_count > repeat_to_reset
            state.population = []
            create_population(state, params)
            old_best_count = 0
        end
    end
    return state.best_word, state.best_cost

end

end
