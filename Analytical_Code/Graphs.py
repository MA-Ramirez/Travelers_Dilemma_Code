import numpy as np
import matplotlib.pyplot as plt

#This script graphs the results obtained using StaDis.py and saved in the Data folder

#-----------------------------------
#------------GRAPHS VARY B----------
#-----------------------------------

#Selection coefficient values
B = np.array([0.01,0.05,0.1,0.5,1.0])
#Strategies
Claims = np.linspace(2,100,99)
#Number of strategies
n=np.size(Claims)
#Abundance of each state
values = np.empty((np.size(B),n))

#Obtain information from files
for i in range(np.size(B)):
    info = np.genfromtxt("Data/Results_"+str(B[i])+"_2.txt")
    values[i] = info

#Verify shape of array
print(np.shape(values))

#------------PHASE PLOT VARY B----------
plt.xscale("log")
plt.ylabel("Claim")
plt.xlabel("Selection intensity coefficient ("+r"$\beta$"+")")
plt.contourf(B,Claims,np.transpose(values),levels=n,cmap="inferno")
plt.colorbar(ticks=np.linspace(0,0.1,11))
plt.savefig("Graphs/Contour_B.png")
plt.clf()

#------------LINE PLOT VARY B----------
cc = np.array(["red","gold","green","blue","darkviolet"])

for i in range(np.size(B)):
    plt.plot(Claims,np.transpose(values[i,:]),color=cc[i],label=str(B[i]))
    print(Claims[np.argmax(values[i,:])])
plt.legend(title = r"$\beta$", loc="best")
plt.xlabel("Claim")
plt.ylabel("Abundance of each claim")
plt.savefig("Graphs/Plot_B.png")
plt.clf()

#-----------------------------------
#------------GRAPHS VARY R----------
#-----------------------------------

#Reward graphs
#R = np.array([10,20,30,40,50])
R = np.array([2,4,6,8,10])
#Abundance of each state
values2 = np.empty((np.size(R),n))

#Obtain information from files
for i in range(np.size(R)):
    info = np.genfromtxt("Data/Results_1.0_"+str(R[i])+".txt")
    values2[i] = info

print(np.shape(values2))

#------------PHASE PLOT VARY R----------
plt.ylabel("Claim")
plt.xlabel("Reward parameter (R)")
plt.contourf(R,Claims,np.transpose(values2), levels=n,cmap="inferno")
plt.colorbar(ticks=np.linspace(0,0.12,7))
plt.savefig("Graphs/Contour_R2.png")
plt.clf()

#------------LINE PLOT VARY R----------
for i in range(np.size(R)):
    plt.plot(Claims,np.transpose(values2[i,:]),color=cc[i],label=str(R[i]))
plt.legend(title = "R", loc="best")
plt.xlabel("Claim")
plt.ylabel("Abundance of each claim")
plt.savefig("Graphs/Plot_R2.png")
plt.clf()
