# Nonlinear and Mixed-integer optimization

This class will cover computational aspects of **integer and nonlinear optimization**, drawing from motivating examples in operations research and machine learning. Please follow the installation instructions below before the class.

## Install Julia packages

In addition to the installation instructions from the previous session, we will use the following packages:
- LinearAlgebra
- Distributions
- Random
- Plots
- Test
- Suppressor
- Gadfly
- DelimitedFiles
- PyPlot
- Test
- TravelingSalesmanHeuristics (via Pkg.clone("https://github.com/evanfields/TravelingSalesmanHeuristics.jl/"))
- Gurobi (see below for installation instructions)
- MosekTools (see below for installation instructions)
- Mosek (see below for installation instructions)

Note: the notebooks used in this session were developed using Julia 1.3, so we encourage you to use this version to be safe.

## Preassignment
For this class, you will be using the Mixed-Integer optimization solver Gurobi and the Conic optimization solver Mosek.

### Install Gurobi

Gurobi is commercial software, but they have a very permissive (and free!) academic license. If you have an older version of Gurobi (>= 7.0) on your computer, that should be fine.

- Go to [gurobi.com](http://www.gurobi.com) and sign up for an account
- Get an academic license from the website (section 2.1 of the quick-start guide)
- Download and install the Gurobi optimizer (section 3 of the quick-start guide)
- Activate your academic license (section 4.1 of the quick-start guide)
- you need to do the activation step while connected to the MIT network. If you are off-campus, you can use the [MIT VPN](https://ist.mit.edu/vpn) to connect to the network and then activate (get in touch if you have trouble with this).
- Test your license (section 4.7 of the quick-start guide)

- Installing packages in Julia is easy with the Julia package manager. Just open Julia and enter the following command:

```jl
pkg> add Gurobi
```

- Some of the functionality of JuMP that we'll be using in this session has not yet been added in a registered version, so we'll be using the master branch version. If you're having trouble with this step (e.g., you're getting errors on the code below), try removing JuMP before re-installing it.

```jl
pkg> add JuMP#master
```

- Let's try a simple LP! Enter the following JuMP code in Julia.

```jl
using JuMP, Gurobi

m = Model(Gurobi.Optimizer)
@variable(m, 0 <= x <= 2 )
@variable(m, 0 <= y <= 30 )

@objective(m, Max, 5x + 3*y )
@constraint(m, 1x + 5y <= 3.0 )

print(m)

optimize!(m)

println("Objective value: ", objective_value(m))
println("x = ", value(x))
println("y = ", value(y))
```

- If Gurobi was installed correctly, you should get an objective value of 10.6.

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
- If Mosek has been installed correctly, you should get an objective value of 10.6.



## Questions?
Email vvdig@mit.edu or ryancw@mit.edu
