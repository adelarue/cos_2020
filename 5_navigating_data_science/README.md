
# Welcome 

This directory holds course materials for Session 5, Navigating the Cycle of Data Science. The core of this session is learning ideas and coding techniques that will help you efficiently navigate the Circle of Data Science: 

![data science](https://ismayc.github.io/moderndiver-book/images/tidy1.png)

Some ideas we'll cover include functional programming, nesting, and never, ever writing for-loops. 

# Before the Session

The `tidyverse` packages should already be installed from Session 3. You will also need the `ggmap` and the `knitr` package. The following code should be sufficient: 

```r
install.packages('tidyverse')
install.packages('leaflet')
install.packages('knitr')
```

To test your installation, paste the following code into your `R` console, and ensure that it runs. 

```{r}
library(tidyverse)
library(knitr)
1:10 %>% 
	purrr::map(~.^2) %>% 
	unlist() %>% 
	as.data.frame() %>% 
	kable()
```

# Mini-Project

Working with your team, create a short PDF report, in which you perform a short machine learning analysis on your data. Your report should answer the following questions: 

1. What is the question you are aiming to answer with your analysis? What is its scientific or operational significance? 
2. What algorithm are you using? Why did you choose that one? 
3. What are the features (independent variables)? Is there a dependent variable? 
4. What was the outcome of your analysis? Is the model "good" and according to which metrics? 

Additionally, your report should include at least one plot. 

Please email your report to Andreea (`andreeag@mit.edu`).



