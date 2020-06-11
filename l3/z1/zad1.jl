
g_domain     = (-5.0, 5.0)
g_particle_c = 86
g_brake_f    = 0.023030
g_global_f   = 0.065025
g_local_f    = 0.043933


mutable struct ParticleStr
    position::Array{Float64}
    speed::Array{Float64}
    best_pos::Array{Float64}
    best_cost::Float64
end


"Read arguments"
function read_args()

    args = map(string, ARGS)
    file_in = args[1]
    file_out = args[2]
    return file_in, file_out

end


"Write result to file"
function write_result(file_out, r_pos, r_cost)

    open(file_out, "w") do file
        write(file, "$(r_pos[1]) $(r_pos[2]) $(r_pos[3]) $(r_pos[4]) $(r_pos[5]) $(r_cost)")
    end

end


"Get run arguments"
function get_in_args(file_in)

    params = []
    open(file_in) do file
        params = split(readline(file), " ")
    end
    return map(x -> parse(Float64, x), params)

end

################################

cost(x, eps) = sum(i -> (eps[i] * (abs(x[i])^i)), range(1, length=5))


"""
Create first solution
# Arguments
- 'c_particles': numer of particles
- 'c_dim': dimensions (default: 5)
"""
function get_first_solution(c_particles::Int, domain::Tuple{Float64, Float64},
            eps::Array{Float64})

    rand_pos() = domain[1] + rand() * (domain[2] - domain[1])
    particles::Array{ParticleStr} = []
    best_pos::Array{Float64}  = []
    best_cost::Float64 = typemax(Float64)
    for x in 1:c_particles
        p_pos = map(x -> rand_pos(), range(1, length=5))
        p_vel = map(x -> rand_pos(), range(1, length=5))
        p_cost = cost(p_pos, eps)
        if p_cost < best_cost
            best_pos = p_pos
            best_cost = p_cost
        end
        p_str = ParticleStr(p_pos, p_vel, copy(p_pos), p_cost)
        push!(particles, p_str)
    end
    return particles, best_pos, best_cost

end


"Update particle speed"
function updateSpeed(particle::ParticleStr, brake_f::Float64,
            global_f::Float64, local_f::Float64, swarm_best_pos::Array{Float64})

    particle.speed = brake_f * particle.speed +
                     rand() * local_f  * (particle.best_pos - particle.position) +
                     rand() * global_f * (swarm_best_pos - particle.position)

end


"Update particle position"
function updatePosition(particle::ParticleStr, domain::Tuple{Float64, Float64},
            eps::Array{Float64}, swarm_best_pos::Array{Float64}, swarm_best_cost::Float64)

    restrict(x::Float64) = min(domain[2], max(domain[1], x))
    particle.position = particle.position + particle.speed
    particle.position = map(p -> restrict(p), particle.position)
    new_cost = cost(particle.position, eps)
    if new_cost < particle.best_cost
        particle.best_pos = particle.position
        particle.best_cost = new_cost
    end
    if new_cost < swarm_best_cost
        swarm_best_pos = particle.position
        swarm_best_cost = new_cost
    end
    return swarm_best_pos, swarm_best_cost

end


"Run particle swarm optimization"
function pso(t, x, eps, params)

    p_domain, p_particle_c, p_brake_f,
        p_global_f, p_local_f = params

    particles, swarm_best_pos, swarm_best_cost = get_first_solution(p_particle_c,
        p_domain, eps)

    start_time = time_ns()
    end_time = start_time + 1e9 * t
    while time_ns() < end_time
        for particle in particles
            updateSpeed(particle, p_brake_f, p_global_f, p_local_f, swarm_best_pos)
            swarm_best_pos, swarm_best_cost = updatePosition(particle, p_domain, eps,
                swarm_best_pos, swarm_best_cost)
        end
    end
    return swarm_best_pos, swarm_best_cost

end


function main()

    file_in, file_out = read_args()
    a = get_in_args(file_in)
    p = [g_domain, g_particle_c, g_brake_f, g_global_f, g_local_f]
    x, fx = pso(a[1], (a[2:6]), (a[7:11]), p)
    write_result(file_out, x, fx)

end


main()
