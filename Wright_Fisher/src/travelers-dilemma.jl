include(srcdir("constants.jl"))

function π(x, y)
    if x > y
        return min(x, y) + PUNISHMENT
    elseif x < y
        return min(x, y) + REWARD
    else
        return min(x,y)
    end
end

"""
    payoff_matrix() → Matrix{Float64}
Payoff matrix of Travelers Dilemma
Return: Payoff Matrix
"""
function payoff_matrix()
    #number of strategies
    n = 99
    A = zeros((n, n))
    for i in 1:n
        for j in 1:n
            A[i,j] = π(i+1,j+1)
            #Sum 1 in i and j because strategy space is [2,100]
        end
    end
    return A
end
