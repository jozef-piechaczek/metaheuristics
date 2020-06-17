include("/home/dzazef/repos/metaheuristics/referat/acs/acs_dsat.jl")
include("/home/dzazef/repos/metaheuristics/referat/acs/acs_rlf.jl")
using .ACS_DSAT
using .ACS_RLF


graph_list = [
    # ("/home/dzazef/repos/metaheuristics/referat/graphs2/65_r250_5.lg", "65"),
    # ("/home/dzazef/repos/metaheuristics/referat/graphs2/84_dsjr_500_1c", "84"),
    # ("/home/dzazef/repos/metaheuristics/referat/graphs2/122_dsjr_500_5.lg", "122"),
    # ("/home/dzazef/repos/metaheuristics/referat/graphs2/234_r1000_5.lg", "??"),
    ("/home/dzazef/repos/metaheuristics/referat/graphs2/xx_dsjc_500_5.lg", "??"),
    ("/home/dzazef/repos/metaheuristics/referat/graphs2/xx_dsjc250_5.lg", "??")
]


ants = 40
q0 = 0.5
alfa = 2.0
beta = 4.0
p = 0.5
iter_to_evaporate = 2
iter_to_reset = 5
eps = 0.65

for (graph_dir, optim) in graph_list
    graph = ACS_DSAT.loadgraph(graph_dir)
    println(graph_dir)
    params_dsat = ACS_DSAT.ParamStr(ants, q0, alfa, beta, p, iter_to_evaporate, iter_to_reset, eps)
    params_rlf = ACS_RLF.ParamStr(ants, q0, alfa, beta, p, iter_to_evaporate, iter_to_reset, eps)
    lf = ACS_DSAT.greedy_color(graph, sort_degree=true).num_colors
    println(">")
    @time begin
        acs_dsat_3 = ACS_DSAT.acs_it(5, params_dsat, graph)
    end
    println(">")
    @time begin
        acs_dsat_10 = ACS_DSAT.acs_it(10, params_dsat, graph)
    end
    # println(">")
    # acs_dsat_15 = ACS_DSAT.acs_it(15, params_dsat, graph)
    println(">")
    @time begin
        acs_rlf_3 = ACS_RLF.acs_it(5, params_rlf, graph)
    end
    println(">")
    @time begin
        acs_rlf_10 = ACS_RLF.acs_it(10, params_rlf, graph)
    end
    # println(">")
    # acs_rlf_15 = ACS_RLF.acs_it(15, params_rlf, graph)
    println(">")
    println("lf: $(lf)")
    println("acs_dsat_5: $(acs_dsat_3)")
    println("acs_dsat_10: $(acs_dsat_10)")
    # println("acs_dsat_15: $(acs_dsat_15)")
    println("acs_rlf_5: $(acs_rlf_3)")
    println("acs_rlf_10: $(acs_rlf_10)")
    # println("acs_rlf_15: $(acs_rlf_15)")
    println("optim: $(optim)")
end
