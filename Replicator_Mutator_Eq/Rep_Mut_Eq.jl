using DynamicalSystems, PyPlot, DelimitedFiles

#-----------------------------------------
#Define payoff matrix Traveler's Dilemma
#-----------------------------------------

#Number of actions
n = 99

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
#Replicator_mutator equation
#-----------------------------------------

#Define mutation matrix
#There is equal prob to move to any other state
#Param: Mu Mutation prob
#Return: Q Mutation matrix
function mutation_Matrix(Mu)
    #Mutation matrix
    Q = zeros((n, n))

    for i in 1:n
        for j in 1:n
            if i != j
                Q[i,j] = Mu/(n-1)
            else
                Q[i,j] = 1-Mu
            end
        end
    end
    return Q
end


#Define dynamic rule for n replicator-mutator equations
#Param: du Solution (iterative)
#Param: u Variables
#Param: p Parameters
#Param: t Time
#Return: Dyn rule to input in DynamicalSystems methods
@inline @inbounds function rep_mutEq!(du, u, p, t)

    #Input payoff matrix as parameter
    A = p[1]
    #Input mutation matrix as parameter
    Q = p[2]

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

    #n replicator-mutator equations
    for i in 1:n
        sum = 0
        for j in 1:n
            sum += X[j]*f[j]*Q[j,i]
        end
        du[i] = sum - X[i]*Avg
    end

    #Output
    return
end

#Define initial conditions
#Param: n Number of claims
#Return: Array of initial conditions
function ini_con()
    ini_con = zeros(n)
    #for i in 1:n
    #    ini_con[i] = 1/n
    #end

    for i in (n-5):n
        ini_con[i] = 1/n
    end
    """
    val = 0.3
    for i in 1:n
        if i > 6
            ini_con[i] = val
        else
            ini_con[i] = (1-3*val)/(n-3)
        end
    end
    """
    return ini_con
end


#Obtains solution trajectories of the system
#Param: R reward/punishment in the payoff scheme
#Param: ini array with initial conditions
#Param: mu Mutation strength
#return: dataset Solution trajectories of the system
function obtain_data(R,ini,mu)
    M = payoff_Matrix(R)
    Q = mutation_Matrix(mu)
    #Paramaters
    p = [M,Q]

    #Generate dynamical system
    #   ContinuousDynamicalSystem(f, state, p; t0 = 0.0)
    #Returns generalized dynsys from dyn rule
    ds = ContinuousDynamicalSystem(rep_mutEq!, ini_con(), p)

    #Time evolution of the system
    #   trajectory(ds::GeneralizedDynamicalSystem, T; kwargs...) → dataset
    #Returns dataset containing trajectory of system ds, after evolving for a total time T
    data = trajectory(ds, 30; Δt = 0.1)
end

#-----------------------------------------
#Functions for handling solution
#-----------------------------------------

#Graphs data and saves it in PNG file
#Param: R reward/punishment in the payoff scheme
#Param: data Solution trajectories of the system
#Param: mu Mutation strength
#Return: PNG file with plot
function graph_data(R,data,mu)
    cmap = get_cmap("rainbow")
    colors = []
    for i in range(0,stop=1,length=n)
        push!(colors,cmap(i))
    end

    for i in 1:n
        if i == 95
            plot(data[:,i],color="black",label=string(i+1))
        else
            plot(data[:,i],color=colors[i],label=string(i+1))
        end
    end

    """
    #Plot trajectories
    for i in 1:n
        if i == 1 || i == n
            plot(data[:,i],color=colors[i],label=string(i+1))
        else
            plot(data[:,i],color=colors[i])
        end
    end
    """


    #title("Claim frequency vs Time")
    xlabel("Time steps (t)")
    ylabel("Claim frequency")
    legend(loc=7, bbox_to_anchor=(1, 0.5),title="Claim", fontsize = "xx-small",ncol=5)
    savefig("Plots/Rep_Mut_eq_"*string(R)*"_"*string(mu)*".png")
    clf()
end

function graph_data_2(R,data,mu)
    cmap = get_cmap("rainbow")
    colors = []
    for i in range(0,stop=1,length=n)
        push!(colors,cmap(i))
    end

    cc = 1
    Names = ["[2-10]","[11-20]","[21-30]","[31-40]","[41-50]","[51-60]","[61-70]",
    "[71-80]","[81-90]","[91-100]"]
    #Plot trajectories
    for i in 1:n
        if mod(i,10) == 9
            plot(data[:,i],color=colors[i],label=Names[cc])
            cc+=1
        else
            plot(data[:,i],color=colors[i])
        end
    end

    #title("Claim frequency vs Time")
    xlabel("Time steps (t)")
    ylabel("Claim frequency")
    legend(loc="center left",title="Claim", fontsize = "x-small", bbox_to_anchor=(1,0.5))
    savefig("Plots/Rep_Mut_eq_"*string(R)*"_"*string(mu)*".png")
    clf()
end

#Obtains which strategy dominates in the population
#Param: R reward/punishment in the payoff scheme
#Param: data Solution trajectories of the system
#Param: mu Mutation strength
#Return: txt file with info [R, winner strategy]
function winner(R, data, mu)
    max = 0
    winner = 0
    for i in 1:n
        temp = last(data[:,i])
        if temp > max
            max = temp
            #+1 given that lower bound of action set is 2
            winner = i+1
        end
    end
    ans = [R mu winner]
    open("Data/winner_mut.txt", "a") do io
        writedlm(io, ans)
    end
end

#-----------------------------------------
#Execute code
#-----------------------------------------

#Set reward values to be evaluated
#R = [2,5,10,15,20,25,30,35,40]
#Mu = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9]
R = [2]
Mu = [0.7]

#Upper bound mutation strength
#Mu = [round((n-1)/n, digits=1, RoundToZero)]
#print(Mu)
#Mu = 0.8

#Set initial conditions (same for all runs)
ini_arr = ini_con()

#Obtain solution trajectories, graph data and obtain dominant strategy
# for all reward values and mutation strength values
for i in R
    for j in Mu
        data_V = obtain_data(i,ini_arr,j)
        graph_data_2(i,data_V,j)
        #winner(i, data_V,j)
    end
end
