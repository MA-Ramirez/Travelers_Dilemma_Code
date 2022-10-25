import numpy as np
import matplotlib.pyplot as plt

#This script obtains the abundance for each claim in the statitonary distribution
#   for given values of R (reward) and B (selection intensity)

#Number of strategies
n = 99
#Dimension
D = n*n
#Reward
R = 2

#Define matrices
#Identity matrix
I = np.identity(D)

print("Identity matrix")
print(I)
print(np.shape(I))

#U matrix (all entries are equal to 1)
U = np.ones((D,D))

print("U matrix")
print(U)
print(np.shape(U))

# e vector (all entries are equal to 1)
e = np.ones((1,D))

print("e vector")
print(e)
print(np.shape(e))


#Defines the payoff matrix of Travelers Dilemma
#Note: I am x, other player is y, for there to be incentive in playing low claims
# If switched, payoff scheme changes
#Param: x My claim
#Param: y Other player claim
#Param: R reward/punishment in the payoff scheme
#Return: My payoff
def payoff(x,y,R):
    if x > y:
        return min(x, y) - R
    elif x < y:
        return min(x, y) + R
    else:
        return min(x,y)


#Payoff matrix of Travelers Dilemma
P = np.empty((n,n))

for i in range(n):
    for j in range(n):
        P[i,j] = payoff(i+2,j+2,R)
        #Sum 2 in i and j because strategy space is [2,100]

print("Payoff matrix")
print(P)
print(np.shape(P))

#Fermi function used in intros. dyn.
#Param: alt Alternative claim
#Param: now Current/realized claim
#Param: B Intensity of selection coefficient
#Return: evaluated Fermi function for input param.
def Fermi(alt,now,B):
    #Difference between alternative payoff and current payoff
    Delta_Pi = alt-now
    deno = 1 + np.exp(-B*Delta_Pi)
    ans = 1/deno
    return ans

#--------------------------------------------
#----------TRANSITION MATRIX VALUES----------
#--------------------------------------------

#The transition matrix is filled by cases

#If P1 changes
#Param: x1 Initial claim player 1
#Param: x2 Final claim player 1
#Param: y Claim player 2
#Param: R Reward parameter
#Param: B Intensity of selection coefficient
#Return: transition prob.
def P1_change(x1,x2,y,R,B):
    cte = 1/(2*(n-1))
    #Initial state P1
    payoff1 = payoff(x1,y,R)
    #Final state P1
    payoff2 = payoff(x2,y,R)
    #Fermi
    FF = Fermi(payoff2,payoff1,B)
    ans = cte*FF
    return ans

#If P2 changes
#Param: y1 Initial claim player 2
#Param: y2 Final claim player 2
#Param: x Claim player 1
#Param: R Reward parameter
#Param: B Intensity of selection coefficient
#Return: transition prob.
def P2_change(x,y1,y2,R,B):
    cte = 1/(2*(n-1))
    #Initial state P2
    payoff1 = payoff(y1,x,R)
    #Final state P2
    payoff2 = payoff(y2,x,R)
    #Fermi
    FF = Fermi(payoff2,payoff1,B)
    ans = cte*FF
    return ans

#If no player changes
#Param: x Claim player 1
#Param: y Claim player 2
#Param: R Reward parameter
#Param: B Intensity of selection coefficient
#Return: transition prob.
#Note: Could be optimized if needed such that all of the values are not
#calculated many times in the matrix
def no_change(x,y,R,B):
    SS = 0
    for i in range(2,101):
        if i != x:
            #Initial state P1
            payoff1 = payoff(x,y,R)
            #Final state P1
            payoff2 = payoff(i,y,R)
            SS += Fermi(payoff2,payoff1,B)
        if i != y:
            #Initial state P2
            payoff1 = payoff(y,x,R)
            #Final state P2
            payoff2 = payoff(i,x,R)
            SS += Fermi(payoff2,payoff1,B)
    cte = 1/(2*(n-1))
    ans = 1 - cte*SS
    return ans

#--------------------------
#-------BASIS VECTORS------
#--------------------------

#The basis vectors are used to fill the transition matrix using indices

#Basis vector 1
BV1 = np.array([])

for i in range(2,101):
    for j in range(n):
        BV1 = np.append(BV1,i)

print("Basis vector 1")
print(BV1)
print(np.shape(BV1))

#Basis vector 2
BV2 = np.array([])

for i in range(n):
    for j in range(2,101):
        BV2 = np.append(BV2,j)

print("Basis vector 2")
print(BV2)
print(np.shape(BV2))

#Sample matrix used to show how a matrix is filled using 2 loops
TO = np.empty((3,3))
ss= 0

for i in range(3):
    for j in range(3):
        TO[i,j] = ss
        ss+=1

print(TO)
print(np.shape(TO))

#--------------------------------------------
#------------FILL TRANSITION MATRIX----------
#--------------------------------------------

#Fills the transition matrix using the cases defined previously
#Param: R Reward parameter
#Param: B Intensity of selection coefficient
#Return: T Transition matrix
def fill_Tmatrix(R,B):
    #Transition matrix
    T = np.empty((D,D))

    #Initial state
    P1i = 0
    P2i = 0
    #Final state
    P1f = 0
    P2f = 0

    for i in range(D):
        for j in range(D):
            #Basis vectors are used to fill the transition matrix
            #   using indices
            P1f = BV1[j]
            P2f = BV2[j]
            P1i = BV1[i]
            P2i = BV2[i]

            #Fill matrix using the cases
            if P1i != P1f and P2i != P2f:
                T[i,j] = 0
            elif P1i != P1f:
                T[i,j] = P1_change(P1i,P1f,P2i,R,B)
            elif P2i != P2f:
                T[i,j] = P2_change(P1i,P2i,P2f,R,B)
            else:
                T[i,j] = no_change(P1i,P2i,R,B)

    return T

#-----------------------------
#-------OBTAIN ABUNDANCES-----
#-----------------------------
#Calculates and saves abundances for given params
#Param: R Reward parameter
#Param: B Intensity of selection coefficient
#Return: File with abundances
def abundances(R,B):
    #Define transition matrix
    T = fill_Tmatrix(R,B)
    print("Transition matrix")
    print(T)
    print(np.shape(T))

    #Obtain u vector
    u = np.dot(e,np.linalg.inv(I+U-T))

    print("u vector")
    print(u)
    print(np.shape(u))

    #To obtain abundance of each claim:
    #   For the 1st claim, sum the first n values
    #   for the 2nd claim, sum the second n values, and so on...

    #Obtain and save abundance of each claim
    stDis = np.array([])
    cc = 0
    Sum = 0
    for i in range(D):
        Sum+=u[0,i]
        cc+=1
        if cc == 99:
            stDis = np.append(stDis,Sum)
            text_file = open("Data/Results_"+str(B)+"_"+str(R)+".txt", "a+")
            n = text_file.write(str(Sum)+"\n")
            text_file.close()
            cc = 0
            Sum = 0

    print("stDis vector")
    print(stDis)
    print(np.shape(stDis))

#-----------------------------
#-------DEFINE PARAMETERS-----
#-----------------------------
#-----**only modify here**----

#R = [2,5,10,15,20,25,30,35,40]
#B = [0.02,0.04,0.06,0.08,0.2,0.4,0.6,0.8]
#B = [0.01,0.05,0.1,0.5]
B = [1.0]
R = [5,15,25,30,35]
