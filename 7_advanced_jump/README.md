# Nonlinear and Mixed-integer optimization

This class will cover computational aspects of **integer and nonlinear optimization**, drawing from motivating examples in operations research and machine learning. Please follow the installation instructions below before the class.

## Install Julia packages

In addition to the installation instructions from the previous session, we will use the following packages:
- LinearAlgebra
- Distributions
- Plots
- Test
- Suppressor
- MosekTools (see below for installation instructions)
- Mosek (see below for installation instructions)

Note: the notebooks used in this session were developed using Julia 1.3, so we encourage you to use this version to be safe.

## Preassignment
For this class, you will be using the Conic optimization solver Mosek.

### Install Mosek
Mosek is commercial software, but they have a very permissive (and free!) academic license. We are asking you to install it in addition to Gurobi, because while Gurobi/CPLEX are state-of-the-art for integer programs,  Mosek is state-of-the-art (and often much faster than Gurobi/CPLEX) for conic problems.

- Go to [mosek.com](https://www.mosek.com/license/request/personal-academic/) and request a personal academic license.
- Fill out all required forms, and download the .lic file.
- Place the license file at the appropriate path directory ("/Users/YourUserNameHere/mosek/mosek.lic" on a Mac, "$HOME/mosek/mosek.lic" on UNIX, "%USERPROFILE%\mosek\mosek.lic" on Windows). If you place it in the wrong directory you will get an error when you try to run Mosek, telling you where to put the license file.
- Install and build the "Mosek", "MosekTools" packages, by running "using Pkg; Pkg.build("Mosek, MosekTools")"
- Test that your installation is working by running the following code:
```jl
using Mosek, MosekTools, JuMP

m=Model(with_optimizer(Mosek.Optimizer))
@variable(m, 0 <= x <= 2 )
@variable(m, 0 <= y <= 30 )

@objective(m, Max, 5x + 3*y )
@constraint(m, 1x + 5y <= 3.0 )

optimize!(m)
# to suppress output, load the Suppressor.jl package and solve by running "@suppress optimize!(m)"

@show "Objective value is: " objective_value(m)
@show "x value is: " value.(x)
@show "y value is: " value.(y)
```
- If Mosek has been installed correctly, you should get an objective value of 10.6



## Questions?
Email vvdig@mit.edu or ryancw@mit.edu
