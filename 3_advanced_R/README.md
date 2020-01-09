# Advanced Wrangling and Visualization in R

In this session we will work towards building a basic interactive dashboard with R's `shiny` framework. In the first part of the session we will deep dive into some of the `tidyverse`'s more advanced functionalities like scoped verbs and grouped mutate/filter. The analysis and plots we make will then be packaged into a `shiny` dashboard in the second half of the session, where we will learn about reactivity and interactive visualization. 

## Pre-assignment 1: Keeping current

To ensure that you have the most current versions of all files, please fire up a terminal, navigate to the directory into which you cloned the full set of materials for the course, and run `git pull`.  (Refer back to Session 1 if you're having trouble here.)

Before class, it is recommended you review Session 2's material on basic `dplyr` verb usage and how to create simple plots with `ggplot2`. If you haven't done so already, please make sure you have completed the pre-assignment for that session and are able to load/use these two `tidyverse` libraries. 

We recommend you follow along in class using the `S3_script.R` file, which will allow you to live-code along with the session leader and work through un-solved exercises.  

It may be helpful, however, to also keep handy the `S3_script_full.R` file which have all code and exercise answers filled in.


## Pre-assignment 2: Installing libraries

In addition to the `tidyverse`, in this session we will be using the `lubridate` library for date manipulation and `shiny` for creating dashboards. 

Install them using the following: 

```
install.packages(c('lubridate', 'shiny'))
```

You should test that all of the libraries will load by then running
```
library(tidyverse)
library(lubridate)
library(shiny)
```

Test that `lubridate` and `ggplot2` work by executing the command: 

```
data.frame(date = ymd('20190113') + days(1:100), sales = rnorm(100, 100, 5)) %>% 
    ggplot(aes(x = date, y = sales)) + geom_line()
```

which should create a random line plot with months on the x-axis. Take a screenshot of this. 

To test your `shiny` installation, create a simple app from `RStudio` by going to `File` -> `New File` -> `Shiny Web App...` -> `Create`. The application name and directory don't matter (you can delete the newly created folder after you finish below). 

This will automatically open a file called `app.R` in your `RStudio`. *You do not need to know what any of the code does, we will cover this in class.* At the top right of the script window, click the `Run App` button, and wait for the new window. Change `Number of Bins` to 20 and take a screenshot of the entire dashboard. 

You will need to close the window before you are able to type into the `RStudio` console again. 

**Please email a screenshot of these two outputs to Arthur (adelarue@mit.edu).**
