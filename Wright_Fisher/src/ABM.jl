using DrWatson

include(srcdir("constants.jl"))
include(srcdir("travelers-dilemma.jl"))


using Agents
using Random: GLOBAL_RNG
using StatsBase: mean
using Distributions: DiscreteUniform

mutable struct Mem1Player <: AbstractAgent
    id::Int
    pos::NTuple{2,Int}
    strategy::Int64
    scores::Vector{Int64}
    fitness::Float64
    LOD::Vector{Int64}
end

function create_model(
    p;
    space = nothing,
    LOD = false,
    rng = GLOBAL_RNG
)

    properties = deepcopy(p)

    properties[:LOD] = LOD

    #properties[:selection] = a -> exp(model.σ * mean(a.scores))
    #properties[:selection] = a -> mean(a.scores)
    #properties[:selection] = a -> model.σ *mean(a.scores)

    model = AgentBasedModel(Mem1Player, space, properties = properties, rng = rng, scheduler = Schedulers.by_id)
    model.n = Int(model.n)


    if model.space === nothing
        for id = 1:model.n
            add_agent!(
                Mem1Player(
                    id,
                    (1, 1),
                    model.init_strategy,
                    Int64[1],
                    1,
                    Int64[]
                ),
                model,
            )
        end
    else
        fill_space!(
            model,
            model.init_strategy,
            Int64[1],
            1,
            Int64[]
        )
    end
    return model
end


function match!((X, Y)::Tuple{Mem1Player,Mem1Player}, model)

    if X.id != Y.id
        push!(X.scores, π(X.strategy, Y.strategy))
        push!(Y.scores, π(Y.strategy, X.strategy))
    end
end


function play_matches!(player, model)

    ## pick competitors
    if model.space === nothing
        competitors = allagents(model)
    else
        competitors = nearby_agents(player, model)
    end

    ## play matches
    for competitor in competitors
        match!((player, competitor), model)
    end

end


function mutate!(player, model)
    if rand(model.rng) < model.μ
        player.strategy += rand(model.rng, DiscreteUniform(-model.δ, model.δ))
    end
    player.strategy = max(min(player.strategy, 100), REWARD)
end

# function window!(x)
#     x = max(min(x, 100), 0)
# end

function player_step!(player, model)
    mutate!(player, model)
    play_matches!(player, model)
end

function WF_sampling!(model)

    #Compute fitness via exponential mapping
    #Simplification done to avoid numerical instability

    #Save scores of all players in array
    arrScores = []
    for a in allagents(model)
        push!(arrScores,mean(a.scores))
    end

    #counter
    CC=1
    #Compute fitness
    for a in allagents(model)
        myScore = arrScores[CC]
        deno = 0.0
        for i in arrScores
            denoVal = exp(model.σ*(i-myScore))
            deno += denoVal
        end
        #Assign fitness value
        a.fitness = 1.0/deno
        #Update counter
        CC+=1
        #Reset scores
        a.scores = Int64[]
        sizehint!(a.scores, model.n^2)
    end

    # Wright-Fisher sampling
    try
        if !model.LOD
            Agents.sample!(model, model.n, :fitness)
        else
            sample_with_LOD!(model, model.n, :fitness)
        end
    catch
        println("arg")
        print([agent.fitness for agent in allagents(model)])
    end

end
