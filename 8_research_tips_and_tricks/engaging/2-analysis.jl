using CSV, DataFrames
using ScikitLearn
using Random, Statistics
using JLD2

# Import the necessary modules and libraries from ScikitLearn
@sk_import ensemble:RandomForestClassifier

# Import our training function which trains a random forest
include("rf.jl")

# Load the data for training and validation


# Load the parameters dataframe


# Get the experiment ID from the arguments that were passed to julia
experiment_id = 1
if length(ARGS) > 0
	experiment_id = parse(Int, ARGS[1])
end

# Set a random seed - always a good idea when using functions you didn't write
Random.seed!(1776)

# Actually run the experiment
