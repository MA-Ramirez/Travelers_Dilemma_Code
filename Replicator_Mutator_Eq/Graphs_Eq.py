import numpy as np
import matplotlib.pyplot as plt

#This script graphs the results obtained using Rep_Mut_Eq.jl

#-----------------------------------
#------------PHASE PLOT-------------
#-----------------------------------

Dom = np.genfromtxt("Data/winner_mut.txt", usecols = 2)

R = np.array([2,5,10,15,20,25,30,35,40])
Mu = np.array([0.0,0.05,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9])

Claims = np.linspace(2,100,99)
n = np.size(Claims)
print(n)

Dom_M = np.zeros((np.size(R),np.size(Mu)))
cc=0
for i in range(np.size(R)):
    for j in range(np.size(Mu)):
        Dom_M[i,j]=Dom[cc]
        cc+=1

#plt.xscale("log")
plt.ylabel("Reward parameter (R)")
plt.xlabel("Mutation strength ("+r"$q$"+")")
plt.contourf(Mu,R,Dom_M,levels=n,cmap="inferno")
plt.colorbar(ticks=[2,10,20,30,40,50,60,70,80,90,97], label="Highest frequency claim")
#plt.colorbar()
plt.savefig("Plots/Contour_RepMut.png")
plt.clf()
