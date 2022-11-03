# Travelers Dilemma Code
Code for the simulations and numerical solutions accompanying the paper _Diversity enables the jump towards cooperation for the Traveler's Dilemma_ by M.A.Ramirez, M.Smerlak, A.Traulsen & J.Jost.

## Using the code
The code is divided in the 3 different methods used for analysing the Traveler's Dilemma
1. Replicator Mutator Equation

Julia scripts to numerically solve the equation. Python script to graph the results. (coded by M.A.Ramirez)

2. Wright-Fisher Model

Julia sub-project to simulate the Wright-Fisher model. It uses [`Agents.jl`](https://juliadynamics.github.io/Agents.jl/stable/), a Julia framework for agent-based modeling. (coded by M.Smerlak)

3. Introspection Dynamics

Python scripts to simulate the dynamics, obtain the stationary distribution numerically and graph the results. (coded by M.A.Ramirez)

## Reproducing the code
The project contains code in Python and Julia, each method contains the corresponding files to locally reproduce them: `environment.yml` (Python) - `Manifest.toml` and `Project.toml` (Julia)
