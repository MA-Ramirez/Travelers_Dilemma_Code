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
using DataFrames, StatsPlots, DataFramesMeta
using Plots
using LinearAlgebra
using CSV

#In all processes the Agents.jl files are executed
@everywhere begin
    include(srcdir("ABM.jl"))
    include(srcdir("constants.jl"))
    include(srcdir("travelers-dilemma.jl"))
end

################################################################################
#                            INITIALIZE SIMULATIONS                            #
################################################################################

#In all processes an ABM is created and returned
@everywhere function initialize(; n, μ, δ, init_strategy = 50, σ = 1.)
    return create_model(Dict{Symbol, Any}(:n => n, :μ => μ, :δ => δ, :init_strategy => init_strategy, :σ => σ))
end

################################################################################
#                                SET PARAMETERS                                #
################################################################################

#Param dictionary - vary μ and δ
params = Dict(  :n => 100,
                :μ => collect(1e-2:5e-3:4e-1),
                :δ => collect(1:20),
                #:μ => collect(1e-2:5e-3:1.5e-2),
                #:δ => [10,15],
                :σ => 0.1
            )

#Set dictionary to save data
Re = REWARD
Sig = params[:σ]
save_params = @strdict Re Sig

################################################################################
#                                RUN SIMULATION                                #
################################################################################

#Perform a parameter scan of a ABM simulation
adata, _ = paramscan(params, initialize;
    agent_step! = player_step!,
    model_step! = WF_sampling!,
    n = 1_000,
    adata = [:strategy],
    parallel = true
    )

################################################################################
#                                    SAVE DATA                                 #
################################################################################

CSV.write(datadir(savename("Average_Payoff",save_params,"csv")),adata)

################################################################################
#                        FUNCTIONS CALCULATE AVERAGE PAYOFF                    #
################################################################################

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
    avg_payoff(freqs_vec) → Float64
Calculates the average payoff of the population
Param: vector containing the frequency of each claim
Return: average payoff of the population
"""
function avg_payoff(freqs_vec)
    PM = payoff_matrix()
    #Get the vector of fitness
    fitness_vec = PM*freqs_vec
    #Get the average fitness of population
    avg_pay = dot(freqs_vec,fitness_vec)

    return avg_pay
end

"""
    get_avgpayoff(info_strategies) → Float64
Runs the functions get_frequencies(info_vec) and avg_payoff(freqs_vec)
Param: Vector containing the strategies of all agents for a given time step
Return: average payoff of the population
"""
function get_avgpayoff(info_strategies)
    freqs = get_frequencies(info_strategies)
    avg_pay = avg_payoff(freqs)
    return avg_pay
end

################################################################################
#                       RUN CALCULATION OF AVERAGE PAYOFF                      #
################################################################################

#Get data from the last time step
final_step = subset(adata, :step => i -> i.== 1000)[!, Not(:id)]

#Calculate average payoff and save in new dataframe
Avg_payoff_info = combine(
        groupby(final_step,["μ","δ"]),
        df -> DataFrame(avg_payoff = get_avgpayoff(df.strategy))
    )

################################################################################
#                          PLOT AVERAGE PAYOFF RESULTS                         #
################################################################################

#Plot data as phase diagram
scatter(
    Avg_payoff_info[:,:μ],
    Avg_payoff_info[:,:δ],
    marker_z = Avg_payoff_info[:,:avg_payoff],
    legend=false,
    colorbar=true,
    clim = (0,100),
    colorbar_ticks=collect(0:10:100),
    markershape = :rect,
    markersize = 10,
    xlabel = "Mutation probability (μ)",
    ylabel = "Maximal mutation size (δ)",
    dpi = 500,
    )

#Save plot
savefig(plotsdir(savename("Average_Payoff",save_params,"png")))
