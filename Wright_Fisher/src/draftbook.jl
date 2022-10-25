set = [400,100,200]

arr = []
for i in set
    push!(arr,i+1)
end

println(arr)

B = 10.0

ww = []
for i in arr
    deno = 0.0
    for j in arr
        denoVal = exp(B*(j-i))
        deno += denoVal
    end
    weight = 1.0/deno
    push!(ww,weight)
end

println(ww)
