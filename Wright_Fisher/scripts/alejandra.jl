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

#In all processes the Agents.jl files are executed
@everywhere begin
    include(srcdir("ABM.jl"))
    include(srcdir("constants.jl"))
end

#In all processes an ABM is created and returned
@everywhere function initialize(; n, μ, δ, init_strategy = 50, σ = 1.)
    return create_model(Dict{Symbol, Any}(:n => n, :μ => μ, :δ => δ, :init_strategy => init_strategy, :σ => σ))
end

#----------------------------------
#------------Time series-----------
#---------------vary μ-------------
#----------------------------------

#Param dictionary - vary μ
params = Dict(  :n => 100,
                :μ => collect(1e-2:3e-2:4e-1),
                :δ => 10,
                :σ => 1
            )

#Perform a parameter scan of a ABM simulation output by collecting data from
    # all parameter combinations into dataframe
adata, _ = paramscan(params, initialize;
    agent_step! = player_step!,
    model_step! = WF_sampling!,
    n = 1_000,
    adata = [(:fitness, mean), (:strategy, mean)],
    parallel = true
    )

#Plot data as time series
@df adata plot(:step, :mean_strategy, group = (:μ), legend = :bottomright,
 xlabel = "Generation (t)", ylabel = "Mean claim", dpi = 300,legendfontsize=5,
 palette = :cmyk)

#Save data in a file with today's date
try
    mkdir(datadir(string(today())))
catch
    @warn "today's directory already exists"
end

#Save data via Apache Arrow
Arrow.write(datadir(string(today()), "vary_mu_delta.arrow"), adata)
#Save plot
savefig(current(), plotsdir("vary_mu.png"))


#-----------------------------------
#-----------Phase diagram-----------
#-----------vary μ and δ------------
#-----------------------------------

#Param dictionary - vary μ and δ
params = Dict(  :n => 100,
                :μ => collect(1e-2:5e-3:4e-1),
                :δ => collect(1:20),
                :σ => 10.0
            )

#Perform a parameter scan of a ABM simulation
adata, _ = paramscan(params, initialize;
    agent_step! = player_step!,
    model_step! = WF_sampling!,
    n = 1_000,
    adata = [(:strategy, mean)],
    parallel = true
    )

#Save data in a file with today's date
begin
    try
        mkdir(datadir(string(today())))
    catch
        @warn "today's directory already exists"
    end
end

#Save data via Apache Arrow
Arrow.write(datadir(string(today()), "vary_mu_delta.arrow"), adata)

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


#----------------------------------
#------------Time series-----------
#-----------vary selection---------
#----------------------------------

"""
#Param dictionary - vary σ
params = Dict(  :n => 100,
                :μ => 1e-1,
                :δ => 10,
                :σ => collect(.01:.05:.4)
            )

#Perform a parameter scan of a ABM simulation
adata, _ = paramscan(params, initialize;
    agent_step! = player_step!,
    model_step! = WF_sampling!,
    n = 1_000,
    adata = [(:strategy, mean)],
    parallel = true
    )

#Plot data as time series
@df adata plot(:step, :mean_strategy, group = (:σ), legend = :bottomright, xlabel = "generation", ylabel = "mean claim", dpi = 300)

#Save data in a file with today's date
try
    mkdir(datadir(string(today())))
catch
    @warn "today's directory already exists"
end

#Save data via Apache Arrow
Arrow.write(datadir(string(today()), "vary_selection.arrow"), adata)

#Save plot
savefig(current(), plotsdir("vary_selection.png"))
"""
