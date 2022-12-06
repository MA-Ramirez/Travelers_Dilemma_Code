#Parallel computing package
using Distributed

#Parallel computing
#The number of logical CPU cores available in the system,
    # i.e. the number of threads that the CPU can run simultaneously
PROCESSES = Sys.CPU_THREADS - 1
#Launches worker processes
addprocs(PROCESSES)

#To use something on every process, the macro @everywhere is used
#DrWatson activates the project in all processes
    # Activate is to install the required packages
@everywhere using DrWatson
@everywhere @quickactivate "TD"

#Packages used for the current plotting script
using Dates
using DataFrames, StatsPlots, Arrow, DataFramesMeta
using Plots
using LinearAlgebra

#In all processes the Agents.jl files are executed
@everywhere begin
    include(srcdir("ABM.jl"))
    include(srcdir("constants.jl"))
    include(srcdir("travelers-dilemma.jl"))
end

#In all processes an ABM is created and returned
@everywhere function initialize(; n, μ, δ, init_strategy = 50, σ = 1.)
    return create_model(Dict{Symbol, Any}(:n => n, :μ => μ, :δ => δ, :init_strategy => init_strategy, :σ => σ))
end

#---------

#Param dictionary - vary μ and δ
params = Dict(  :n => 100,
                :μ => collect(1e-2:5e-3:1.5e-2),
                #:μ => 1e-2,
                :δ => 15,
                :σ => 10.0
            )

println(params)

#Perform a parameter scan of a ABM simulation
adata, _ = paramscan(params, initialize;
    agent_step! = player_step!,
    model_step! = WF_sampling!,
    n = 1_000,
    adata = [:strategy],
    parallel = true
    )

"""
    get_frequencies(info_vec) → Vector{Float64}
Obtains vector containing frequencies of each strategy [2,100]
For a given time step calculates the frequency of each strategy and saves it in a vector
ie. First element is the frequency of claim = 2
... Last element is the frequency of claim = 100
Param: Vector containing the strategies of all agents for a given time step
Return: Vector with the frequencies of each strategy
"""
function get_frequencies(info_vec)
    num_strategies = 99
    ans = zeros(num_strategies)

    for i in 1:num_strategies
        #i+1 because action set is [2,100]
        #Relative amounts
        ans[i] = (count(el->(el== i+1), info_vec)/100.0)
    end
    return ans
end

"""
    avg_payoff(freqs_vec) → Vector{Float64}
Calculates the average payoff of the population
Param: vector containing the frequency of each claim
Return: average payoff of the population for a given time step
"""
function avg_payoff(freqs_vec)
    PM = payoff_matrix()
    #Get the vector of fitness
    fitness_vec = PM*freqs_vec
    #Get the average fitness of population
    avg_pay = dot(freqs_vec,fitness_vec)

    return avg_pay
end


#Save data in a file with today's date
begin
    try
        mkdir(datadir(string(today())))
    catch
        @warn "today's directory already exists"
    end
end

#Save data via Apache Arrow
#Arrow.write(datadir(string(today()), "vary_mu_delta.arrow"), adata)

#Get average payoff
last_step_strategies = adata[adata.step .== 1000, :strategy]
freqs = get_frequencies(last_step_strategies)
avg_pay = avg_payoff(freqs)
println(avg_pay)
println(size(avg_pay))
println(typeof(avg_pay))

"""
#Plot data as phase diagram
scatter(
    adata[adata.step .== 1000, :μ],
    adata[adata.step .== 1000, :δ],
    #title = "reward = $REWARD, punishment = $PUNISHMENT",
    legend = :bottomleft,
    legendfontsize=5,
    marker_z = adata[adata.step .== 1000, :mean_strategy],
    #label = "Mean claim at t = 1000",
    legend=false,
    markershape = :rect,
    markersize = 10,
    xlabel = "Mutation probability (μ)",
    ylabel = "Maximal mutation size (δ)",
    dpi = 500,
    )

#Save plot
savefig(plotsdir("phase-diagram"))
"""
