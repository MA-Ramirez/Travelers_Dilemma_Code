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