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

Sigma = parse(Float64,ARGS[1])

#Param dictionary - vary μ and δ
params = Dict(  :n => 100,
                :μ => collect(1e-2:5e-3:4e-1),
                :δ => collect(1:20),
                #:μ => collect(1e-2:5e-3:1.5e-2),
                #:δ => [10,15],
                :σ => Sigma
            )

#Set dictionary to save data
R = REWARD
save_params = @strdict R Sigma

################################################################################
#                                RUN SIMULATION                                #
################################################################################

#Perform a parameter scan of a ABM simulation
adata, _ = paramscan(params, initialize;
    agent_step! = player_step!,
    model_step! = WF_sampling!,
    n = 1_000,
    adata = [(:strategy, mean)],
    parallel = true
    )

################################################################################
#                                    SAVE DATA                                 #
################################################################################

CSV.write(datadir(savename("AverageClaim",save_params,"csv")),adata)

################################################################################
#                          PLOT AVERAGE CLAIM RESULTS                         #
################################################################################

#Plot data as phase diagram
scatter(
    adata[adata.step .== 1000, :μ],
    adata[adata.step .== 1000, :δ],
    marker_z = adata[adata.step .== 1000, :mean_strategy],
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
savefig(plotsdir(savename("AverageClaim",save_params,"png")))
