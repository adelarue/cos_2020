# Install the packages we need for the session
install.packages(c("tidyverse", "modelr", "ROCR",
                   "caTools", "rpart", "rpart.plot", "leaflet",
                   "RColorBrewer", "glmnet", "randomForest"))

# Load the packages we need to validate the installation
library(glmnet)
library(tidyverse)
library(randomForest)

e_net <- glmnet(matrix(c(1,2,3,4,3,4,5,6), nrow = 4), c(2,4,6,8))
e_net$beta[1,]
# The output should match up with "output-1.png"

