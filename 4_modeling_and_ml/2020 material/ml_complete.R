#' ---
#' title: "Session 4: Modeling and Machine Learning"
#' output: html_document
#' ---
#' 
## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

#' 
## ----libraries, message=FALSE-------------------------------------------------
library(modelr)
library(glmnet)
library(tidyverse)
library(caTools)
library(randomForest)
library(ROCR)
library(rpart)
library(rpart.plot)
library(RColorBrewer)
library(leaflet)

#' 
#' 
#' ## This Session
#' 
#' Now that you've had some experience using R for data wrangling and presentation, we're going to look at **model selection** and **model evaluation** in this session.
#' 
#' Model selection means choosing an algorithm which acts on the data available to us, and produces a solution to the task we aim to solve.
#' 
#' Model evaluation means assessing *how well* the solution we obtain solves the task.
#' 
#' We're going to get some practice for three common types of task in machine learning:
#' 
#' 1. Regression (supervised learning)
#' 2. Classification (supervised learning)
#' 3. Clustering (unsupervised learning)
#' 
#' It's important to note that model selection and evaluation are not followed sequentially in practice, but instead iterated over. We'll try to get a sense of what this looks like in the session.
#' 
#' 
#' ## Regression
#' 
#' We're going to start by solving a regression problem.
#' 
#' **Inputs**
#' 
#' Regression is a supervised learning problem, which means that we have access to a dataset $\mathcal{D} = \{ (x_i, y_i) \}_{i = 1}^{n}$ where each $x_i \in \mathbb{R}^d$ and each $y_i \in \mathbb{R}$.
#' 
#' Note that for regression, the output, $y$, is *continuous*.
#' 
#' **Aim**
#' 
#' The aim of a regression task is to find a function $h: \mathbb{R}^d \to \mathbb{R}$ which allows us to compute an accurate prediction of the output, $y$, for any given input, $x$. These new $x$ and $y$ are *unseen*: that is, we assume they are identically distributed relative to the points in $\mathcal{D}$, but independent.
#' 
#' Exactly what we mean by *accuracy* will be discussed when we talk about model evaluation.
#' 
#' The way we approach the problem of finding $h$ is by selecting a parameterised class of models, and solving an optimization problem to find the best model within this class according to a *loss function*. We usually repeat this process for several model classes.
#' 
#' 
#' ### Defining our Regression Task
#' 
#' We're going to use the Boston Airbnb dataset, where each entry is a property listing, and aim to use the input variables available to us in order to predict the price of a listing.
#' 
#' Note here that we haven't specified exactly which variables in the dataset will be used to define each $x_i$. This is a choice which is part of the modeling process, and we will iterate on it.
#' 
#' First, we load the full dataset, and a processed version of it:
#' 
## -----------------------------------------------------------------------------
source("process_listings.R")

listings_full <- process_listings("../../data/listings.csv")

listings <- listings_full %>%
  
  # Take only the columns that we need.
  select(price, accommodates, review_scores_rating, property_type, neighbourhood_cleansed, room_type) %>%
    
  # Convert characters to factors.
  mutate_if(is.character, as.factor)

#' 
#' Let's have a look:
#' 
## -----------------------------------------------------------------------------
head(listings)

#' 
#' 
#' ### Ordinary Least Squares
#' 
#' The first class of models we're going to try is linear models. This means we hypothesise that the output, $y$, can be described using a linear combination of the inputs, $x$: $h(x) = w^{\intercal} x$.
#' 
#' Ordinary Least Squares (OLS) finds the best fitting linear model according to the least squares loss function:
#' 
#' $$\min_w \: \frac{1}{n} ||X w - Y||_2^2$$
#' 
#' where $e_{i}^{\intercal} X = x_{i}^{\intercal}$, and $e_{i}^{\intercal} Y = y_i$. This is equivalent to:
#' 
#' $$\min_w \: \frac{1}{n} \sum_{i = 1}^{n} (w^{\intercal} x_i - y_i)^2$$
#' 
#' We won't talk about the details behind solving this problem, but the optimal $w^{*}$ can be written in closed form.
#' 
#' **Question**: What are the tunable parameters (hyperparameters) for the class of OLS models?
#' 
#' **Answer**: There aren't really any. If we restrict ourselves to OLS, then the only choice we need to make is which variables to include as inputs.
#' 
#' 
#' #### Fitting an OLS Model 
#' 
#' Now, we need to choose exactly which inputs will be used for fitting the model. Which inputs might be predictive of price? Recall the column names:
#' 
## -----------------------------------------------------------------------------
names(listings)

#' 
#' For a very simple model, let's just choose `accommodates` as the only input. To fit this model we use the base R function `lm`:
#' 
## -----------------------------------------------------------------------------
ols_model <- lm(price ~ accommodates, data = listings)

#' 
#' What's happening here? The first argument makes use of R's formula interface. In words, we want the output `price` to be explained by the input `accommodates`.
#' 
#' The second (named) argument supplies the data we're using to build the model -- this is where R looks for the names (`price` and `accommodates`) contained in the formula. We will see some more complicated formulae later in the session.
#' 
#' Let's check out the `ols_model` object. It's a list of relevant information generated by the function call, and we can use `$` to view different elements:
#' 
## -----------------------------------------------------------------------------
names(ols_model)

#' 
#' The function `summary` is overloaded for many different objects and often gives a useful snapshot of the model:
#' 
## -----------------------------------------------------------------------------
summary(ols_model)

#' 
#' Let's look at the 'coefficients' section. In the 'estimate' column, we see that the point estimates for the model coefficients say that the price is \$55.20 plus \$37.79 for every person accommodated. Notice the star symbols at the end of the '(Intercept)' and 'accommodates' rows indicate that according to a statistical t-test, both coefficients are significantly different from 0.
#' 
#' To visualise the model, let's plot the fitted line. There are some nifty functions in the `modelr` package that make interacting with models easy within the `tidyverse` setting. We'll use `modelr::add_predictions`:
#' 
## -----------------------------------------------------------------------------
listings %>%	
  add_predictions(ols_model, var = "pred") %>%
  ggplot(aes(x = accommodates)) +
  geom_point(aes(y = price)) +
  geom_line(aes(y = pred), color = 'red') +
  labs(title = "OLS Model Fit")

#' 
#' Nice. We can also remove the linear trend and check the residuals directly, which we'll do here using `modelr::add_residuals`.
#' 
#' This is helpful to check whether the residuals looks like random noise rather than an unidentified trend (which would indicate that a linear model is not a good hypothesis for the relationship):
#' 
#' **Exercise**: Using `modelr::add_residuals`, produce a scatter plot which shows the model residuals.
#' 
## -----------------------------------------------------------------------------
listings %>%
  add_residuals(ols_model, var = "resid") %>%
  ggplot(aes(x = accommodates, y = resid)) + 
  geom_point() +
  labs(title = "OLS Model Residuals")

#' 
#' Due to the closely spaced values, box plots might tell a better story:
#' 
#' **Exercise**: Using `modelr::add_residuals`, produce a box plot of model residuals for each accommodation size.
#' 
## -----------------------------------------------------------------------------
listings %>%	
  add_residuals(ols_model, var = "resid") %>%
  ggplot(aes(x = as.factor(accommodates), y = resid)) + 
  geom_boxplot() +
  labs(title = "OLS Model Residual Boxplots")

#' 
#' **Question**: What do these box plots tell us about the model?
#' 
#' **Answer**: Although the residuals seem relatively centered around zero, there does appear to be some right skew. Also, the 9 and 10-person accommodation residuals look less centered. Perhaps the model doesn't apply so well here.
#' 
#' 
#' ### Evaluation
#' 
#' Now we're going to look at two measures of accuracy for regression models -- in other words, how well a model explains a dataset.
#' 
#' The first is the mean squared error (MSE), which is simply computed as the mean of the squared residuals. Recall that the residuals are stored in the `ols_model` object:
#' 
## -----------------------------------------------------------------------------
mse <- mean(ols_model$residuals ^ 2)
mse

#' 
#' `modelr::rmse` also gives us an easy way of calculating (root) MSE from a model applied to a dataset:
#' 
## -----------------------------------------------------------------------------
rmse(ols_model, listings) ^ 2

#' 
#' Clearly this measure is highly affected by the scale of the data. We can also use the 'R squared' coefficient as a more interpretable measure of accuracy, since it falls between 0 and 1. It is the *proportion of variance in the data which is explained by the model*, and is calculated as:
#' 
## -----------------------------------------------------------------------------
rsq <- 1 - mse / mean((listings$price - mean(listings$price)) ^ 2)
rsq

#' 
#' The `rmodel::rsquare` function also calculates it for us:
#' 
## -----------------------------------------------------------------------------
rsquare(ols_model, listings)

#' 
#' The R squared value is what we will use to evaluate the performance of our models in this session. But, it's important to note that this is definitely not the only choice we could have made!
#' 
#' **Question**: What is the relationship between the loss function and the measure of accuracy used to evaluate a model? How do we know which is the best choice for each?
#' 
#' **Answer**: The loss function is used to fit a model, and the measure of accuracy is used to evaluate how well it explains the data. The measure of accuracy usually comes from the task we aim to solve, and the loss function is often something that we will play around with until we find a good model. 
#' 
#' 
#' #### Training, Validation and Testing Splits
#' 
#' Recall that our ultimate goal in this supervised learning task is to be able to predict price ($y$) from an *unseen* set of inputs ($x$, although we are still playing around with the input variables which define it).
#' 
#' When building the OLS model, we used the entire dataset. Simply taking the R squared value on this dataset as a measure of performance is clearly not fair -- since we want the model to generalise to unseen data.
#' 
#' To address this problem, we often split the dataset into three different chunks:
#' 
#' 1. **Training data**: the data we build our models on.
#' 2. **Validation data**: the data we tune hyperparameters on.
#' 3. **Testing data**: the data we use to obtain a final estimate of performance.
#' 
#' The validation set is like an 'intermediate' estimate of performance. If we didn't use the validation set for this purpose, the only way of selecting the best model from a model class would be to look at its performance on the training set or the testing set.
#' 
#' `modelr::resample_partition` provides an easy way of creating these data partitions:
#' 
## -----------------------------------------------------------------------------
set.seed(0)
part <- resample_partition(listings, c(train = .6, val = .2, test = .2))

#' 
#' This produces a list of three `resample` objects:
#' 
## -----------------------------------------------------------------------------
names(part)

#' 
#' In order to save space, these are just pointers to rows in our data -- meaning we lose some of the conveniences of working with tibbles. Since our dataset is relatively small, we can just convert them back to tibbles:
#' 
## -----------------------------------------------------------------------------
part_tib <- part %>% map(as_tibble)

#' 
#' 
#' ### Model Iteration
#' 
#' Now that we're equipped to build models and evaluate their performance, let's start iterating to find better models.
#' 
#' We've glossed over the precise choice of variables to use in order to explain price, so let's try a few different combinations. This sounds like a job for a loop, but since we're working with `dplyr` it's better to think of writing functions.
#' 
#' First, note that the `lm` function also works with a string supplied for the formula:
#' 
## -----------------------------------------------------------------------------
lm("price ~ accommodates", data = part_tib$train)

#' 
#' Now we'll write a function that accepts a formula and training/validation/testing partitioning, and returns the R squared value on each partition, the model formula, and the model itself:
#' 
#' **Exercise**: Write this function.
#' 
## -----------------------------------------------------------------------------
eval_ols <- function(form, part) {
  ols_model <- lm(form, data = part$train)
  
  result <- tibble(model = list(ols_model),
                   formula = form,
                   train_rsq = rsquare(ols_model, part$train),
                   val_rsq = rsquare(ols_model, part$val),
                   test_rsq = rsquare(ols_model, part$test))
  
  return(result)
}

#' 
#' Now let's create a list of formulae to try:
#' 
## -----------------------------------------------------------------------------
forms <- list(
  "price ~ accommodates",
  "price ~ accommodates + review_scores_rating",
  big_formula <- "price ~ accommodates + review_scores_rating + property_type + neighbourhood_cleansed + accommodates * room_type"
)

#' 
#' **Question**: Does the third formula still correspond to a linear model?
#' 
#' **Answer**: We have created some nonlinear features, so not technically. But we still fit a 'linear' model to these new features -- think of it as augmenting the input vector, $x$, with new features, and then fitting a pure linear model.
#' 
#' And now we'll build and evaluate a series of OLS models together, one for each formula:
#' 
#' **Exercise**: Using the function previously defined, build and evaluate the models.
#' 
## -----------------------------------------------------------------------------
ols_models <- forms %>%
  map(~eval_ols(., part_tib)) %>%
  bind_rows()
ols_models

#' 
#' **Question**: Can we say anything definitive about these results?
#' 
#' **Answer**: We can be relatively confident that the largest model is the best performing. We also see that the testing performance is significantly worse than the training performance. Usually this indicates overfitting, but then why is the validation performance so similar to the training performance? This is most likely due to our performance estimates being sensitive to the randomness used to select the training/validation/testing partitions. We can check this by changing the random seed defined earlier. Cross-validation, which we will introduce, is one way of addressing this problem.
#' 
#' 
#' ### Regularization
#' 
#' In some situations, overfitting is more obvious -- and since it is a common problem when building models, we will now look at how it can be addressed.
#' 
#' Regularization is a tool which helps us to avoid overfitting by penalising model complexity. Mathematically, we add a term to the loss function in the optimisation problem to be solved. Recall that the OLS formulation we've worked with is:
#' 
#' $$\min_w \: \frac{1}{n} \sum_{i = 1}^{n} (w^\intercal x_i - y_i)^2$$
#' 
#' With a regularization term, this becomes:
#' 
#' $$\min_w \: \frac{1}{n} \sum_{i = 1}^{n} (w^\intercal x_i - y_i)^2 + \lambda \Omega(w)$$
#' 
#' $\Omega(w)$ is a penalty on the complexity of the model. Two common choices for $\Omega(w)$ are:
#' 
#' 1. $\Omega(w) = ||w||_2^2$: this is ridge regression.
#' 2. $\Omega(w) = ||w||_1$: this is LASSO regression.
#' 
#' Both types of regression shrink the elements of the optimal $w^*$ vector towards 0 -- but in different ways. We will focus on LASSO -- which tends to shrink the coefficients so that some are equal to 0. This is nice because it helps us interpret the model by making it *sparser*.
#' 
#' We'll use the `glmnet` package. This package illustrates some of the less desirable aspects of R, since it doesn't work very elegantly with the `tidyverse` (it uses matrix representations of the data rather than data frame representations).
#' 
#' Let's check out the function `glmnet::glmnet`:
#' 
## -----------------------------------------------------------------------------
?glmnet

#' 
#' Notice that `glmnet` doesn't use formulae. Instead, it accepts a matrix of input variables and a vector of outputs.
#' 
#' Fortunately, R has the `model.matrix` function which takes a data frame and processes it for `glmnet` and other functions with this type of input. This also includes creating dummy variables for categorical variables in the original dataset.
#' 
#' We'll use the `big_formula` that we made previously for our linear regression, but we have to remove the dependent variable. Let's first see how the model fitting process works with our entire dataset:
#' 
## -----------------------------------------------------------------------------
model_formula <- as.formula(gsub("price", "", big_formula))
X <- model.matrix(model_formula, data = listings)
Y <- as.vector(listings$price)

#' 
#' The X matrix that's been produced looks like:
#' 
## -----------------------------------------------------------------------------
head(X)

#' 
#' Let's fit our first LASSO model. There is a way to specify lambda manually, but let's just accept the default for now and see what happens.
#' 
## -----------------------------------------------------------------------------
lasso_model <- glmnet(X, Y)

#' 
#' The `summary` function is not quite as helpful this time:
#' 
## -----------------------------------------------------------------------------
summary(lasso_model)

#' 
#' It does give us some information, though. Notice that `lambda` is a vector of length 76. The `glmnet` function has defined 76 different values of lambda and found the corresponding optimal weight vector (here called `beta`) for each one. We have 76 different models.
#' 
#' **Question**: As a sanity check: where does the length of `beta`, 2584, come from?
#' 
#' **Answer**: We have 76 different models, and the dimension of the `X` matrix is (3501 by 34). Note that 76 x 34 = 2584.
#' 
#' Let's look at some of the coefficients for the different models. We'll start with one where lambda is really high, and check how many coefficients are nonzero:
#' 
## -----------------------------------------------------------------------------
lasso_model$lambda[1]
nnzero(lasso_model$beta[, 1])

#' 
#' Here the penalty on the size of the coefficients is so high that R sets them all to zero. Moving to smaller lambda:
#' 
## -----------------------------------------------------------------------------
lasso_model$lambda[10]
lasso_model$beta[which(lasso_model$beta[, 10] != 0), 10]	

#' 
## -----------------------------------------------------------------------------
lasso_model$lambda[20]
lasso_model$beta[which(lasso_model$beta[, 20] != 0), 20]

#' 
#' As the size of lambda decreases, the fitted models have more and more nonzero coefficients. We can visually see the path of all the coefficients as lambda is tuned by plotting the model:
#' 
## -----------------------------------------------------------------------------
plot(lasso_model, xvar = "lambda")

#' 
#' Each line is one variable. The plot is quite messy with so many variables, but it gives us the idea. As lambda grows, the size of the weight vector `beta` is penalised more, and so more coefficients are set to zero.
#' 
#' 
#' ### Cross-Validation
#' 
#' Now that we can fit LASSO models to a dataset, we need a way of selecting the one with the best parameter for our task.
#' 
#' **Question**: How would we do this using the training/validation/testing splits we have previously defined?
#' 
#' **Answer**: Fit models on the training set, varying lambda. Then obtain an estimate of performance for each model on the validation set, and choose the best. Obtain a final estimate of performance for this model on the testing set.
#' 
#' Here, because the `glmnet` library makes it easy, we're going to use a similar technique called cross-validation. Generally, we only consider this necessary when we're worried we have too little training data to obtain an accurate estimate of validation performance.
#' 
#' The idea behind cross-validation is: repeating the training/validation process multiple times provides us with several estimates of validation performance. Taking the average of these hopefully gives us an estimate which is less affected by noise.
#' 
#' To cross-validate, we start with only two partitions of the dataset:
#' 
#' 1. Combined training/validation set: the data that we repeatedly train and validate on.
#' 2. Testing set: the data we obtain our final performance estimate on.
#' 
#' But, how do we train and validate?
#' 
#' - First, select a number of *folds*.
#' - Then divide the training/validation data into this number of equal-sized partitions.
#' - For each fold, repeat the training/validation procedure. The fold is the validation data, and the other folds are training data.
#' - Average the performance of each model across folds and pick the hyperparameters which produce the best model.
#' - Fit a model on the entire training set using the selected values of hyperparameters.
#' 
#' Since `glmnet` makes use of matrices, let's convert the same training/validation/testing splits as before into matrix form:
#' 
## -----------------------------------------------------------------------------
make_matrices <- function(df, input_formula, output_name){
  X <- model.matrix(input_formula, data = df)
  Y <- df %>% pull(output_name)
  return(list(X = X, Y = Y))
}

part_merge <- list(train = bind_rows(part_tib$train, part_tib$val), test = part_tib$test)
part_mat <- part_merge %>% map(~make_matrices(., model_formula, "price"))

#' 
#' The `glmnet` package has a very handy function called `glmnet::cv.glmnet` which performs cross-validation automatically. Let's look at the function arguments:
#' 
## -----------------------------------------------------------------------------
?cv.glmnet

#' 
#' Not too different to before. Note that the default number of folds is 10, which is fine for our purposes. Also note that the default performance metric is mean squared error, which is also fine (since it is closely related to the R squared measure). Let's do the cross-validation:
#' 
## -----------------------------------------------------------------------------
lasso_model_cv <- cv.glmnet(part_mat$train$X, part_mat$train$Y)

#' 
#' And check what the model object looks like:
#' 
## -----------------------------------------------------------------------------
summary(lasso_model_cv)

#' 
#' Notice the `lambda.min` attribute. This is the best lambda determined by the cross-validation. `lambda.1se` is the largest lambda such that the *error is within 1 standard error of the minimum*.
#' 
#' The standard `plot` function works nicely with cross-validated `glmnet` models to show the error for each model:
#' 
## -----------------------------------------------------------------------------
plot(lasso_model_cv)

#' 
#' The first vertical dotted line shows `lambda.min`, and the second is `lambda.1se`. The figure illustrates how we can find the 'sweet spot' by varying lambda. The left-hand side of this graph is flatter than we'd sometimes see, meaning that the unpenalized model may not be too bad -- however, increasing lambda increases interpretability at close to no loss in prediction accuracy!
#' 
#' We still haven't obtained an error measurement on the testing data, which will allow us to compare our best regularised model with the unregularised one. Because we're using `glmnet`, we need to use the `predict` function rather than `modelr::add_predictions`:
#' 
## -----------------------------------------------------------------------------
?predict.cv.glmnet

#' 
#' We also can't use the performance measures in the `modelr` library, so we have to calculate R squared manually.
#' 
## -----------------------------------------------------------------------------
pred_test <- predict(lasso_model_cv, newx = part_mat$test$X, s = "lambda.min")
R2_lasso <- 1 - sum((pred_test - part_mat$test$Y) ^ 2) / sum((mean(part_mat$test$Y) - part_mat$test$Y) ^ 2)
R2_lasso

#' 
#' The previous best model had a test error of 0.416, so we now have a slightly better model. Regularization has also given us a way of obtaining an accurate model with fewer nonzero coefficients (by using `lambda.1se`):
#' 
## -----------------------------------------------------------------------------
index <- which(lasso_model_cv$lambda == lasso_model_cv$lambda.1se)
nnzero(lasso_model_cv$glmnet.fit$beta[, index])

#' 
#' 
#' ## Classification
#' So far we've looked at models which predict a continuous response variable. There are many related models which predict categorical outcomes, such as whether an email is spam or not, or which digit a handwritten number is. We'll take a brief look at three of these: logistic regression and classification trees.
#' 
#' ### Logistic Regression
#' Logistic regression is part of the class of generalized linear models (GLMs), which build directly on top of linear regression. These models take the linear fit and map it through a non-linear function. Linear regression has the form $$y_i=w_0+w_1 x_{i,1}+w_2 x_{i,2}=w^Tx_i,$$ whereas a GLM model has the form $$y_i=f(w^Tx_i)$$ For logistic regression, the function $f()$ is given by $f(z) = 1/(1+\exp(-z))$ (the *logistic function*), which looks like this:	
#' 
## -----------------------------------------------------------------------------
zs <- seq(-10, 10, 0.25)
ys <- exp(zs) / (1 + exp(zs))
plot(zs, ys)

#' 
#' Since the function stays between zero and one, it can be interpreted as a mapping from predictor values to a probability of being in one of two classes. 
#' 
#' In OLS regression, the coefficients $w$ were chosen so that they minimize mean squared error:
#' $\min_w \: \frac{1}{n} \sum_{i = 1}^{n} (w^{\intercal} x_i - y_i)^2$
#' 
#' And we heard that the optimal $w^{*}$ can be written in closed form. If we tried to minimize mean squared error for logistic regression, we would *not* be able to obtain $w^{*}$ easily. Intuitively, we also might want a different loss function. We want to penalize misclassification (e.g. classifying something that is not spam as spam). For logistic regression, the objective is instead to minimize **logistic loss**:
#' $$\min_w\: \frac{1}{n}\sum_{i = 1}^{n} -y_i \log(f(w^Tx_i))-(1-y_i)\log(1-f(w^Tx_i))$$
#' When $y_i=1$, this function looks like this:
## -----------------------------------------------------------------------------
zs <- seq(0, 1, 0.01)
loss <- -log(zs)
plot(zs, loss)

#' 
#' And when $y_i=0$, this function looks like this:
## -----------------------------------------------------------------------------
zs <- seq(0, 1, 0.01)
loss <- -log(1-zs)
plot(zs, loss)

#' So when the true value of $y_i$ is 1, the function **heavily** penalizes predicted $y_i$'s close 0, and vice versa.
#' 
#' Let's apply this model to the `listings` data. Let's try to predict which listings have elevators in the building by using `price` as a predictor. This information is contained in the `amenities` column. Let's see what this column looks like:
## -----------------------------------------------------------------------------
head(listings_full$amenities)

#' This column also contains information which could be useful for prediction, if we can come up with a clean way of representing the amenities. Our goal here is to turn the amenities column into many columns, one for each amenity, and with logical values indicating whether each listing has each amenity. This is just a bit tricky, so I've written a function called `expand_amenities` that will do this for us. We need to `source()` the file that has this function in it, and then we'll call it on the `listings_full` data frame.	
#' 
## -----------------------------------------------------------------------------
source("expand_amenities.R")
listingsBig <- expand_amenities(listings_full)

#' 
#' An indicator for each amenity is now stored in a column called `amentity_x` where `x` is the amenity of interest. Now back to our task of predicting which listings have elevators. To make sure we're asking a sensible question, we'll only consider apartments priced at $500 or less. We will use the command `sample.split` from the `caTools` library to split the data. One nice thing about using `sample.split` for classification is that it preserves the ratio of class labels in the training and testing sets.
#' 
## -----------------------------------------------------------------------------
listingsGLM <- listingsBig %>%
  filter(property_type == "Apartment", price <= 500)
set.seed(123)
spl <- sample.split(listingsGLM$amenity_Elevator_in_Building, SplitRatio = 0.7)
listingsGLMTrain <- subset(listingsGLM, spl == TRUE)
listingsGLMTest <- subset(listingsGLM, spl == FALSE)

#' 
#' Instead of the `lm()` function, we'll now use `glm()`, but the syntax is almost exactly the same:	
#' 
## -----------------------------------------------------------------------------
l.glm <- glm(amenity_Elevator_in_Building ~ price,
             family = "binomial", data = listingsGLMTrain)
summary(l.glm)

#' 
#' Again, we can add predictions to the data frame and plot these along with the actuals, although the result doesn't look nearly as clean:	
#' 
## -----------------------------------------------------------------------------
listingsGLMTest %>%
  mutate(pred = predict(l.glm, newdata = listingsGLMTest, type = "response")) %>%
  ggplot(aes(x = price)) + 
  geom_line(aes(y = pred)) + 
  geom_point(aes(y = amenity_Elevator_in_Building + 0))

#' 
#' One way to get a more informative plot is by using the `logi.hist.plot()` function in the `popbio` package.	
#' 
#' In the meantime, we can explore out-of-sample performance. Ultimately, we want to predict whether or not a listing has an elevator. However, logistic regression gives us something a bit different: a probability that each listing has an elevator. This gives us flexibility in the way we predict. The most natural thing would be to predict that any listing with predicted probability above 0.5 *has* an elevator, and any listing with predicted probability below 0.5 *does not have* an elevator. But what if I use a wheelchair and I want to be really confident that there's going to be an elevator? I may want to use a cutoff value of 0.9 rather than 0.5. In fact, we could choose any cutoff value and have a corresponding prediction model.	
#' 
#' There's a really nice metric that measures the quality of all cutoffs simultaneously: *AUC*, for "Area Under the receiver operating characteristic Curve." That's a mouthful, but the idea is simpler: For every cutoff, we'll plot the *false positive rate* against the *true positive rate* and then take the area under this curve. (A *positive* in our case is a listing that has an elevator. So a *true positive* is a listing that we predict has an elevator and really does have an elevator, while a *false positive* is a listing that we predict has an elevator and does *not* actually have an elevator. The *true positive rate* is the number of true positives divided by the total number of positives, and the *false positive rate* is the numbe of false positives divided by the total number of negatives.)	
#' 
#' **Question**: As a sanity check: What is the true positive rate and false positive rate of a random classifier that chooses `has an elevator` with probability of $\alpha$? (i.e. a classifier that randomly predicts *positive* $\alpha$% of the time.) What is the AUC for this classifier?
#' 
#' **Answer**: Both the true positive rate and false positive rate are $\alpha$. The AUC is 0.5.
#' 
#' As the cutoff decreases from 1 to 0, the rate of total positives will increase. If the rate of true positives increases faster than the rate of false positives, this is one indication that the model is good. This is what AUC measures.	
#' 
#' The `ROCR` package is one implementation that allows us to plot ROC curves and calculate AUC. Here's an example:	
## -----------------------------------------------------------------------------
pred_test <- predict(l.glm, newdata = listingsGLMTest, type = "response")	
pred_obj <- prediction(pred_test, listingsGLMTest$amenity_Elevator_in_Building)
# Creating a prediction object for ROCR	
perf <- performance(pred_obj, 'tpr', 'fpr')	
plot(perf, colorize = T)  # ROC curve
performance(pred_obj, 'auc')@y.values  # AUC - a scalar measure of performance	

#' 
#' As you can see, the `performance()` function in the `ROCR` package is versatile and allows you to calculate and plot a bunch of different performance metrics. In our case, this model gives an AUC of 0.68. The worst possible is 0.5 - random guessing. We're definitely better than random here, and could likely improve by adding more predictors.	
#' 
#' **Exercise**: Add more variables to Logistic Regression. Try to beat the out-of-sample performance for logistic regression of elevators on price by adding new variables. Compute the out-of-sample AUC of the final model, and plot the ROC curve.
#' 
## -----------------------------------------------------------------------------
l.glm_2 <- glm(amenity_Elevator_in_Building ~
                 price + neighbourhood_cleansed,
               family = "binomial", data = listingsGLMTrain)

pred_test <- predict(l.glm_2, newdata = listingsGLMTest, type = "response")
pred_obj <- prediction(pred_test, listingsGLMTest$amenity_Elevator_in_Building)
perf <- performance(pred_obj, 'tpr', 'fpr')
performance(pred_obj, 'auc')@y.values
plot(perf, colorize = TRUE)

#' 
#' Evaluation and iteration are also important when choosing classification models. The same technique of splitting the data into a training, validation, and testing sets should used when performing a model selection task.
#' 
#' We've covered basic logistic regression, but just as with linear regression there are many, many extensions. For example, we could do regularized logistic regression if we wanted to use many predictors, using the `glmnet` package.	
#' 
#' ## Classification Trees 
#' We will briefly explore classification trees (often referred to as CART, for Classification And Regression Trees).
#' 
#' A (binary) classification tree makes predictions by grouping similar observations and then assigning a probability to each group using the proportion of observations within that group that belong to the positive class. Groups can be thought of as nodes on a tree, and tree branches correspond to logical criteria on the predictor variables. There's a lot of neat math that goes into building the trees, but we won't get into that today. For now let's get familiarized by looking at a simple example. We will use the `rpart` library.	
#' 
#' The model construction step follows the same established pattern. We use the modelling function `rpart()`, which takes a formula
#' and a data frame (and optional parameters) as arguments.	
## -----------------------------------------------------------------------------
l.rpart <- rpart(amenity_Elevator_in_Building ~ price + 
                   neighbourhood_cleansed,
                 data = listingsGLMTrain)	
summary(l.rpart)	

#' 
#' This is another case when the `summary()` function is less helpful. We can plot the resulting tree using the `rpart.plot` package:	
## -----------------------------------------------------------------------------
prp(l.rpart)

#' To evaluate the prediction accuracy of our classification tree, we count up the number of times each of the following occurs:
#'  * Y = 1, prediction = 1 (True Positive)
#'  * Y = 0, prediction = 1 (False Positive)
#'  * Y = 1, prediction = 0 (False Negative)
#'  * Y = 0, prediction = 0 (True Negative)
#' A table that holds these values is called a "confusion matrix". Then, accuracy = ( # True Positives +  # True Negatives) / (Total # of observations) 
#' 
#' Let's calculate the training and testing accuracy for our model:
## -----------------------------------------------------------------------------
pred_train <- predict(l.rpart)
confusionMatrixTrain <- table(listingsGLMTrain$amenity_Elevator_in_Building,
                              ifelse(pred_train > 0.5, "pred = 1", "pred = 0"))
accTrain <- sum(diag(confusionMatrixTrain)) / nrow(listingsGLMTrain)
print(accTrain)
pred_test <- predict(l.rpart, newdata = listingsGLMTest)
confusionMatrixTest <- table(listingsGLMTest$amenity_Elevator_in_Building,
                             ifelse(pred_test > 0.5, "pred = 1", "pred = 0"))
accTest <- sum(diag(confusionMatrixTest)) / nrow(listingsGLMTest)
print(accTest)

#' 
#' What is the baseline out-of-sample accuracy? This is just the frequency of the most common class in the training set.
## -----------------------------------------------------------------------------
table(listingsGLMTest$amenity_Elevator_in_Building)
prop.table(table(listingsGLMTest$amenity_Elevator_in_Building))

#' About 70% of the the listings do not have elevators, so if were predicted `no elevator` for every listing, we would get 70% accuracy. This is our naive baseline. Our tree has an accuracy of about 80%, so it is a significant improvement on the baseline.
#' 
#' ### Tuning the CART model
#' If we want to construct high accuracy decision tree models, then we need to tune the parameters.  CART has many parameters that specify how the decision tree is constructed, but one of the most important is cp, the complexity parameter. 
#' cp is a non-negative parameter which typically takes values like 0.1, 0.1, 0.01, 0.001, etc. (default = 0.01). It is the minimum complexity threshold that the CART algorithm uses to decide whether or not to make a split.  So:
#' *If cp is low => low splitting threshold => big tree
#' *If cp is high => high splitting threshold => small tree
#' Similar to lambda in the LASSO model, cp controls the "complexity" of the model, so it important to tune it to avoid over-fitting or under-fitting. You can think of it like this:
#' *If the tree is too big => too many splits => we have an over-fitting problem.
#' *If the tree is too small => too few splits => we have an under-fitting problem.
#' We want to find a tree in the middle, that is "just right". The rpart package makes it easy to perform tune cp via cross-validation. Basically, we start out with a big tree, then "prune" it down to get the right sized tree. Let's begin by constructing a tree with a small cp parameter, which will vary depending upon the problem.  Here, let's do 0.001.
#' 
## -----------------------------------------------------------------------------
treeBig <- rpart(amenity_Elevator_in_Building ~ price + neighbourhood_cleansed,
                 data = listingsGLMTrain,
                 cp = 0.001)
prp(treeBig)

#' 
#' We can use the `printcp()` command to see the cross-validated error for different values of cp, where:
#' * "nsplit"    = number of splits in tree
#' * "rel error" = scaled training error
#' * "xerror"    = scaled cross-validation error
#' * "xstd"      = standard deviation of xerror
## -----------------------------------------------------------------------------
printcp(treeBig)

#' 
#' Cool, so rpart automatically computes all of the cross-validated errors for trees with cp = 0.001 and up! We can also see these results visually using the `plotcp` command.  In this plot:
#' *size of tree = (number of splits in tree) + 1
#' *the dotted line occurs at 1 std. dev. above the minimum xerror
#' 
## -----------------------------------------------------------------------------
plotcp(treeBig)

#' 
#' One rule of thumb is to select the cp value which which produces the smallest value of `xerror` in the output from the `printcp` command, which also corresponds to the minimum of plot above. Another method is to choose the cp value that first goes below the dotted line, and then prune the tree using this value.  We will use the the second method, and select cp=0.011.
## -----------------------------------------------------------------------------
treeFinal <- prune(treeBig, cp = 0.011)
prp(treeFinal)

#' 
#' In this case, because the best cp value = 0.011 is very close to thedefault cp value of 0.01, this tree is identical to the initial tree that we constructed.  This occurs because the best tree in this case is relatively simple. Note that we could have also computed the confusion matrices, training/testing accuracy, and baseline accuracy for our logistic regression model. We can also try looking at a more detailed graph of the tree.
## -----------------------------------------------------------------------------
rpart.plot(treeFinal)

#' 
#' Let's save the plot as a pdf
## -----------------------------------------------------------------------------
pdf("finalTree.pdf", width = 5, height = 2)
rpart.plot(treeFinal)
dev.off()

#' 
#' **Exercise**: Tuning a CART model. Let's try building a more complicated CART model and tune the parameters. Using the formula below, build a CART model to predict `neighbourhood_cleansed` based on price and all of the amenities, tuning the cp parameter. Plot the final tree with the option "varlen = 0"
## -----------------------------------------------------------------------------
amenities_string <- listingsGLMTrain %>%
  select(starts_with("amenity")) %>%
  names() %>%
  paste(collapse = " + ")
tree_formula <- as.formula(paste("neighbourhood_cleansed ~ price", 
                                 amenities_string, sep = " +  "))

#' 
## -----------------------------------------------------------------------------
treeBig2 <- rpart(tree_formula,
                  data = listingsGLMTrain,
                  cp = 0.001)
plotcp(treeBig2)
treeFinal2 <- prune(treeBig2, 0.0024)
prp(treeFinal2, varlen =  0)

#' 
#' 
#' ## Random Forests
#' We will briefly take a look at random forests, using the `randomForest` package. A random forest is a collection of slightly randomized decision trees (hence the name "forest"), and can be used for classification or prediction. They often have excellent predictive performance, but can be expensive to train. Random forests have many hyperparameters that can be tuned to achieve the best possible predictive performance. Perhaps the most important hyperparameter is the number of trees to include in the forest. More trees results in a longer training time but can improve prediction and decrease overfitting. Other parameters can be seen by inspecting the randomForest command:
## -----------------------------------------------------------------------------
?randomForest

#' 
#' Let's start by training a random forest model for a classification task. We will perform the same task of predicting whether or not a listing has an elevator, using price and neighborhood as predictors. We will compare the performance of random forest to what we got using our simple CART model. We'll try two models, one using 5 trees and one using 50 trees.
## -----------------------------------------------------------------------------
set.seed(123)
listingsGLMTrain$amenity_Elevator_in_Building=as.factor(listingsGLMTrain$amenity_Elevator_in_Building)
listingsGLMTrain$neighbourhood_cleansed=as.factor(listingsGLMTrain$neighbourhood_cleansed)
rf <- randomForest(amenity_Elevator_in_Building ~ price+neighbourhood_cleansed,
                   data = listingsGLMTrain, ntree = 5)
pred_train <- predict(rf)
confusionMatrixTrain <- table(listingsGLMTrain$amenity_Elevator_in_Building,
                              ifelse(pred_train==TRUE, "pred = 1", "pred = 0"))
accTrain <- sum(diag(confusionMatrixTrain)) / nrow(listingsGLMTrain)
print(accTrain)

listingsGLMTest$amenity_Elevator_in_Building=as.factor(listingsGLMTest$amenity_Elevator_in_Building)
listingsGLMTest$neighbourhood_cleansed=as.factor(listingsGLMTest$neighbourhood_cleansed)
pred_test <- predict(rf,newdata = listingsGLMTest)
confusionMatrixTest <- table(listingsGLMTest$amenity_Elevator_in_Building,
                             ifelse(pred_test==TRUE, "pred = 1", "pred = 0"))
accTest <- sum(diag(confusionMatrixTest)) / nrow(listingsGLMTest)
print(accTest)

#' 
#' Now we will train a random forest with 100 trees:
## -----------------------------------------------------------------------------
rf <- randomForest(amenity_Elevator_in_Building ~ price+neighbourhood_cleansed,
                   data = listingsGLMTrain, ntree = 100)
pred_train <- predict(rf)
confusionMatrixTrain <- table(listingsGLMTrain$amenity_Elevator_in_Building,
                              ifelse(pred_train==TRUE, "pred = 1", "pred = 0"))
accTrain <- sum(diag(confusionMatrixTrain)) / nrow(listingsGLMTrain)
print(accTrain)
pred_test <- predict(rf,newdata = listingsGLMTest)
confusionMatrixTest <- table(listingsGLMTest$amenity_Elevator_in_Building,
                             ifelse(pred_test==TRUE, "pred = 1", "pred = 0"))
accTest <- sum(diag(confusionMatrixTest)) / nrow(listingsGLMTest)
print(accTest)

#' 
#' Compare this to what we got using rpart, which had accTrain=0.8189944 and accTest=0.8031291. So random forest with only 5 trees does not do very well, but with 100 trees it is doing a bit better than CART! It would likely outperform CART even more if more variables were used and the other hyperparameters of the random forest model were properly tuned.
#' 
#' We will now use random forest for the regression task of predicting `price` from `accomodates`.
## -----------------------------------------------------------------------------
set.seed(123)
spl <- sample.split(listings$price, SplitRatio = 0.7)
listingsTrain <- subset(listings, spl == TRUE)
listingsTest <- subset(listings, spl == FALSE)

#' 
#' For linear regression, the code was:	
## -----------------------------------------------------------------------------
lm1 <- lm(price ~ accommodates, data = listingsTrain)

#' 
#' Using Random Forest, we can write
## -----------------------------------------------------------------------------
rf <- randomForest(price ~ accommodates,
                   data = listingsTrain, ntree = 100)

#' We can compare the performance of the random forest model to the linear regression model by plotting the predictions of each model:
## -----------------------------------------------------------------------------
listingsTrain %>%
  gather_predictions(lm1, rf) %>%
  ggplot(aes(x = accommodates)) +	
  geom_point(aes(y = price)) +	
  geom_line(aes(y = pred, color = model))

#' The predictions from these two models look very similar in the case that `accomodates` is less than 7.5. For larger values of `accomodates`, the random forest model is able to capture the nonlinear trend.
#' 
#' ## Unsupervised Learning
#' Thus far, our machine learning task has been to predict labels, which were either continuous-valued (for regression) or discrete-valued (for classification).  To do this, we input to the ML algorithms some known (feature, label) examples (the training set), and the ML algorithm outputs a function which enables us to make predictions for some unknown (feature, ?) examples (the testing set).  This problem setup is known as **Supervised Learning**.
#' 
#' Next, we consider **Unsupervised Learning**, where we are not given labelled examples, and we simply run ML algorithms on (feature) data, with the purpose of finding interesting structure and patterns in the data.  Let's run one of the widely-used unsupervised learning algorithms, **k-means clustering**, on the `listings` data frame to explore the Airbnb data set.
#' 
#' First, let's look at help page for the function `kmeans()`:
#' 
## -----------------------------------------------------------------------------
?kmeans

#' 
#' Let's create a new data.frame `listings_numeric` which has the subset of columns that we wish to cluster on.  For the `kmeans()` function, all of these columns must be numeric.
## -----------------------------------------------------------------------------
listings_numeric <- listings_full %>%
  select(id, latitude, longitude, accommodates, bathrooms, 
         bedrooms, review_scores_rating, price) %>%
  mutate(price = as.numeric(gsub("\\$|,", "", price))) %>%
  na.omit()
str(listings_numeric)

#' Next, run the **k-means** algorithm on the numeric data.frame, with `k = 5` cluster centers:
## -----------------------------------------------------------------------------
set.seed(1234)
kmeans_clust <- kmeans(listings_numeric[,-1:-3],
                       5, iter.max = 1000, nstart = 100)

#' 
#' What are the characteristics of these 5 groups?  How many listings are in each cluster?
## -----------------------------------------------------------------------------
kmeans_clust$centers
table(kmeans_clust$cluster)

#' Finally let's take a look at where the clusters are located; to do this we  will use a package called `leaflet`; additionally to help us get a good color scheme we will use `RColorBrewer`.
#' 
#' To look at color scheme options we can simply type:
## -----------------------------------------------------------------------------
display.brewer.all(type="qual") # Type can be set to 'div', 'seq', 'qual', or 'all'

#' 
#' Let's visualize the distribution of clusters from the houses; first we need to add our cluster labels to the data and then we will define a color palette that leaflet can use to help us.
## -----------------------------------------------------------------------------
listings_numeric = listings_numeric %>% 
  mutate(clust_label = as.factor(kmeans_clust$cluster))

#' Now we need to define a color palette that to distinguish the clusters; since we have five cluters we will need five distinct colors
## -----------------------------------------------------------------------------
pal = colorFactor(palette = "Set1", domain = listings_numeric$clust_label)

#' 
#' Now let's plot the houses by cluster
## -----------------------------------------------------------------------------
leaflet(listings_numeric) %>% 
  addTiles() %>% 
  addCircleMarkers(~longitude, ~latitude, color = ~pal(clust_label))

#' 
#' Can you see where the clusters are?  Also, what is the proper number of clusters? We will revisit this in the next session, because it requires some more advanced tidyverse tools.  Stay tuned!
#' 
#' In this module, we have covered examples of machine learning methods for linear regression (ordinary and penalized) and classification (supervised and unsupervised).  This is just the tip of the iceberg.  There are tons more machine learning methods which can be easily implemented in R.  
