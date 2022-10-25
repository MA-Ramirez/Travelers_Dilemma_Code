using DynamicalSystems, PyPlot, DelimitedFiles

#-----------------------------------------
#Define payoff matrix Traveler's Dilemma
#-----------------------------------------

#Number of actions
n = 9

#Defines the payoff matrix of Travelers Dilemma
#Note: I am x, other player is y, for there to be incentive in playing low claims
# If switched, payoff scheme changes
#Param: x My claim
#Param: y Other player claim
#Param: R reward/punishment in the payoff scheme
#Return: My payoff
function payoff(x,y,R)
    if x > y
        return min(x, y) - R
    elseif x < y
        return min(x, y) + R
    else
        return min(x,y)
    end
end

#Payoff matrix of Travelers Dilemma
#Returns TD payoff matrix for a given reward value
#Param: n Number of claims
#Param: R reward/punishment in the payoff scheme
#Return: Payoff Matrix
function payoff_Matrix(R)
    A = zeros((n, n))
    for i in 1:n
        for j in 1:n
            A[i,j] = payoff(i+1,j+1,R)
            #Sum 1 in i and j because strategy space is [2,100]
        end
    end
    return A
end


#-----------------------------------------
#Replicator equation
#-----------------------------------------

#Define dynamic rule for n replicator equations
#Param: du Solution (iterative)
#Param: u Variables
#Param: p Parameters
#Param: t Time
#Return: Dyn rule to input in DynamicalSystems methods
@inline @inbounds function repEq!(du, u, p, t)

    #Input payoff matrix as parameter
    A = p[1]

    #Define vector of variables
    X = []
    for i in 1:n
        push!(X,u[i])
    end

    #Define fitness values
    f = []
    for i in 1:n
        push!(f,(A*X)[i])
    end

    #Average fitness
    Avg = transpose(X)*A*X

    #n replicator equations
    for i in 1:n
        du[i] = X[i]*(f[i]-Avg)
    end

    #Output
    return
end

#Define initial conditions
#Param: n Number of claims
#Return: Array of initial conditions
function ini_con()
    ini_con = zeros(n)

    """
    val = 0.3
    for i in 1:n
        if i > 6
            ini_con[i] = val
        else
            ini_con[i] = (1-3*val)/(n-3)
        end
        #ini_con[i] = 1/n
    end
    """
    for i in 1:n
        ini_con[i] = 1/n
    end

    return ini_con
end

#Obtains solution trajectories of the system
#Param: R reward/punishment in the payoff scheme
#Param: ini array with initial conditions
#return: dataset Solution trajectories of the system
function obtain_data(R,ini)
    #Obtain payoff matrix
    M = payoff_Matrix(R)
    #Paramaters
    p = [M]

    #Generate dynamical system
    #   ContinuousDynamicalSystem(f, state, p; t0 = 0.0)
    #Returns generalized dynsys from dyn rule
    ds = ContinuousDynamicalSystem(repEq!, ini, p)

    #Time evolution of the system
    #   trajectory(ds::GeneralizedDynamicalSystem, T; kwargs...) → dataset
    #Returns dataset containing trajectory of system ds, after evolving for a total time T
    data = trajectory(ds, 200; Δt = 0.1)
    return data
end

#-----------------------------------------
#Functions for handling solution
#-----------------------------------------

#Graphs data and saves it in PNG file
#Param: R reward/punishment in the payoff scheme
#Param: data Solution trajectories of the system
#Return: PNG file with plot
function graph_data(R,data)

    #Use colormap to choose colors of plots
    cmap = get_cmap("rainbow")
    colors = []
    for i in range(0,stop=1,length=n)
        push!(colors,cmap(i))
    end

    #Plot trajectories
    for i in 1:n
        if i == 1
            plot(data[:,i],color="black",label=string(i+1))
        elseif i == n
            plot(data[:,i],color="deeppink",label=string(i+1))
        else
            plot(data[:,i],color=colors[i],label=string(i+1))
        end
    end

    #Graph Aesthetics
    #title("Claim frequency vs Time")
    xlabel("Time steps (t)")
    ylabel("Claim frequency")
    legend(loc=7,title="Claim", fontsize = "small")
    savefig("Plots/Rep_eq_"*string(R)*".png")
    clf()
end

#Obtains which strategy dominates in the population
#Param: R reward/punishment in the payoff scheme
#Param: data Solution trajectories of the system
#Return: txt file with info [R, winner strategy]
function winner(R, data)
    max = 0
    winner = 0
    for i in 1:n
        temp = last(data[:,i])
        if temp > max
            max = temp
            #+1 given that lower bound of interval is 2
            winner = i+1
        end
    end
    ans = [R winner]
    open("Data/winner.txt", "a") do io
        writedlm(io, ans)
    end
end

#-----------------------------------------
#Execute code
#-----------------------------------------

#Set reward values to be evaluated
#R = [2,5,10,15,20,25,30,35,40]
R=[2]

#Set initial conditions (same for all runs)
ini_arr = ini_con()

#Obtain solution trajectories, graph data and obtain dominant strategy
# for all reward values
for i in R
    data_V = obtain_data(i,ini_arr)
    graph_data(i,data_V)
    #winner(i, data_V)
end
