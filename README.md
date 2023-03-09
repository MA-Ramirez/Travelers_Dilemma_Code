# Travelers Dilemma Code
Code for the simulations and numerical solutions accompanying the paper:

**_Diversity enables the jump towards cooperation for the Traveler's Dilemma_ by M.A.Ramirez, M.Smerlak, A.Traulsen & J.Jost**

See the published paper [here](https://www.nature.com/articles/s41598-023-28600-5)

## Using the code
The code is divided in the 3 different methods used for analysing the Traveler's Dilemma
1. Replicator Mutator Equation

The code to numerically solve the equation, and to graph and analyse the results is available at:

[https://github.com/MA-Ramirez/Replicator_Mutator_Eq](https://github.com/MA-Ramirez/Replicator_Mutator_Eq)

2. Wright-Fisher Model

Julia sub-project to simulate the Wright-Fisher model. It uses [`Agents.jl`](https://juliadynamics.github.io/Agents.jl/stable/), a Julia framework for agent-based modeling.

3. Introspection Dynamics

Python scripts to simulate the dynamics, obtain the stationary distribution numerically and graph the results. 

## Reproducing the code
The project contains code in Python and Julia, each method contains the corresponding files to locally reproduce them: `environment.yml` (Python) - `Manifest.toml` and `Project.toml` (Julia)
