# Introduction to Julia and JuMP

This is intended to be an "advanced" introduction to Julia and JuMP.
Julia is a "high-level, high-performance dynamic programming language for technical computing", and JuMP is a library that allows us to easily formulate optimization problems and solve them using a variety of solvers.

## Preassignment - Install Julia and IJulia

The first step is to install a recent version of Julia. The current version is 1.3. Binaries of Julia for all platforms are available [here](https://julialang.org/downloads/)

IJulia is the Julia version of IPython/Jupyter, that provides a nice notebook interface to run julia code, together with text and visualization.

Install the IJulia package.
You can invoke the package manager in Julia by pressing `]` from the Julia REPL.
You can add IJulia with:
```
(v1.3) pkg> add IJulia
```
or in the normal Julia REPL:
```
julia> Pkg.add("IJulia")
```

## Preassignment - get familiar with the notebook

### What is a Jupyter Notebook?
- Jupyter notebooks are documents (like a Word document) that can contain and run code.
- They were originally created for Python as part of the IPython project, and adapted for Julia by the IJulia project.
- They are very useful to prototype, draw plots, or even for teaching material like this one.
- The document relies only on a modern browser for rendering, and can easily be shared.

You can start a notebook with:
```
julia> using IJulia
julia> notebook()
```
and navigate to the appropriate directory.

### Navigating the notebook
Click Help -> User Interface Tour for a guided tour of the interface.
Each notebook is composed of cells, that either contain code or text (Markdown).
You can edit the content of a cell by double-clicking on it (Edit Mode).
When you are not editing a cell, you are in Command mode and can edit the structure of the notebook (cells, name, options...)

- Create a cell by:
	- Clicking Insert -> Insert Cell
	- Pressing a or b in Command Mode
	- Pressing Alt+Enter in Edit Mode
- Delete a cell by:
	- Clicking Edit -> Delete Cell
	- Pressing dd
	- Execute a cell by:
	- Clicking Cell -> Run
	- Pressing Ctrl+Enter

Other functions:

- Undo last text edit with Ctrl+z in Edit Mode
- Undo last cell manipulation with z in Command Mode
- Save notebook with Ctrl+s in Edit Mode
- Save notebook with s in Command Mode
Though notebooks rely on your browser to work, they do not require an internet connection (except for math rendering).

### Get comfortable with the notebook
Notebooks are designed to not be fragile. If you try to close a notebook with unsaved changes, the browser will warn you.

Try the following exercises:

[Exercise]: Close/open
1. Save the notebook
2. Copy the address
3. Close the tab
4. Paste the address into a new tab (or re-open the last closed tab with Ctrl+Shift+T on Chrome)

*The document is still there, and the Julia kernel is still alive! Nothing is lost.*

[Exercise]: Zoom
Try changing the magnification of the web page (Ctrl+, Ctrl- on Chrome).

*Text and math scale well (so do graphics if you use an SVG or PDF backend).*

[Exercise]: MathJax

1. Create a new cell, and select the type Markdown (or press m)
2. Type an opening \$, your favorite mathematical expression, and a closing \$.
3. Run the cell to render the $\LaTeX$ expression.
4. Right-click the rendered expression.

## Install other packages we will use
Run `] add` to add the following packages:
1. BenchmarkTools
2. JuMP
3. Random
4. Ipopt
5. ForwardDiff
6. GLPK

Run `using <package name>` in the Julia REPL (e.g. `using JuMP`) to test
there are no errors with the packages you added.

## Questions?
Email lkap@mit.edu
