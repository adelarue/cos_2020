# Install the packages we need for the session.
install.packages(c("tidyverse", "modelr", "ROCR",
                   "caTools", "rpart", "rpart.plot", "leaflet",
                   "RColorBrewer", "glmnet", "randomForest"))

# Load the packages we need to validate the installation.
library(glmnet)
library(modelr)
library(tidyverse)
library(randomForest)

# Test glmnet. The output should match up with "output-1.png".
e_net <- glmnet(matrix(c(1,2,3,4,3,4,5,6), nrow = 4), c(2,4,6,8))
e_net$beta[1,]

# Test randomForest. The output should match up with "output-2.png".
set.seed(123)
df=cbind(data.frame(y=runif(1000)),data.frame(matrix(runif(20*1000),nrow=1000)))
rf=randomForest(y~.,data=df,ntrees=5) # this might take a few seconds to run
summary(rf)

# Test modelr. The output should match "output-3.png".
df %>%
  add_residuals(rf, var = "resid") %>%
  select(y, resid) %>%
  head()
