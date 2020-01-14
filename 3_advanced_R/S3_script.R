#' -------------------------------------------------------------------------
#' Advanced Tidyverse
#' By Ted Papalexopoulos
#' -------------------------------------------------------------------------

#' In this session we will work towards building a bare-bones version of the 
#' AirBnB website, where we can explore prices and map listings for a potential
#' stay. This script will help us build the "server"-side functions that manipulate
#' data for shiny to use. As we build them up we will look at advanced functionalities
#' of dplyr and data merging. 
#' 
#' 
#' Prior to running any code, you probably want to go to 
    #' Session > Set Working Directory > To Source File Location
#' 
#' Then make sure you set up the relative paths in the read_csv() calls below
#' so that you are able to read in the two datasets, which are located in 
#' cos_2020/data/

#' Load libraries ----------------------------------------------------------

library(tidyverse) #' includes dplyr, tidyr, ggplot2
library(lubridate) #' for manipulating dates and times

#' For the analysis we are going to do today, we need two data sets: 
#' - The `listings` data set contains detailed information about each space.
#' - The `calendar` data set contains, for each listing, the availability
#'   and total price per night over the next year. 
#' 
#' We will use updated version of the datasets which should be available in 
#' the data directory.
listings = read_csv('../data/listings_2019.csv')
calendar = read_csv('../data/calendar_2019.csv')

#' ----------------------------------------------
#' RECAP
#' ----------------------------------------------
#' Let's recall the main verbs of dplyr:
#'   `filter()` to select rows based on their values.
#'   `arrange()` to reorder rows.
#'   `select()` and `rename()` to select columns based on their names.
#'   `mutate()` to add new columns that are functions of existing columns
#'   `summarise()` to condense multiple values to a single value.

#` Filter only listings that are "Downtown", and rating is above 80
listings %>% 
    filter(neighbourhood_cleansed == "Downtown", 
           review_scores_rating > 80) %>%
    glimpse


#` Sorts the rows by descending rating
listings %>% 
    arrange(desc(review_scores_rating)) %>% 
    glimpse


#' Creates a data frame with only the `name` and `review_score_rating` columns, and rename
#' the latter to `rating`
listings %>% 
    select(id, review_scores_rating) %>% 
    rename(rating = review_scores_rating) %>% 
    glimpse


#' Replaces NAs with 0 in the `review_score_rating`. Now `clean_rating` is
#' a new column appended at the end of the data frame.
listings %>%
    mutate(clean_rating = ifelse(
                            is.na(review_scores_rating), 
                            0, 
                            review_scores_rating)) %>%
    select(name, review_scores_rating, clean_rating)


#' Calculates the total number of listings and their overall mean rating (`na.rm = T` will omit missing values)
listings %>%
    summarise(n = n(),
              mean_rating = mean(review_scores_rating, na.rm = T)) 


#' Bonus verb: `count(...)` will count the number of occurences of each combination of values
listings %>% count(property_type, bedrooms)


#' ----------------------------------------------
#' GROUP_BY
#' ----------------------------------------------
#' The `group_by(...)` verb creates groups of observations that other verbs will adjust their behaviour to. 

#' `group_by() %>% select()` will be the same but also keep the grouping variables
listings %>% 
    group_by(neighbourhood_cleansed) %>% 
    select(review_scores_rating)


#' `group_by() %>% summarise()` will perform aggregation within each group
listings %>% 
    group_by(neighbourhood_cleansed) %>% 
    summarise(n = n(), 
              mean_rating = mean(review_scores_rating, na.rm = T)) 
    

#' `group_by() %>% arrange()` will be the same, UNLESS `.by_group=TRUE` in which case 
#' it sorts by the groups first and only then by the columns you asked for
listings %>% 
    select(neighbourhood_cleansed, name, review_scores_rating) %>%  # for viewability
    group_by(neighbourhood_cleansed) %>%
    arrange(desc(review_scores_rating), .by_group = T) 

#' `group_by() %>% mutate()` and `group_by() %>% filter()` are the most powerful, and what 
#' we'll focus on the most.
#' 
#' The main difference is that any function you call will be called for each group *separately*. 
#' The function should return either a single value, which will be appended as is to every row in the 
#' group, or a vector of the same length as the number of observations.  
#' 
#' As a first example, let's add a column `delta_avg_rating` to every row that is the difference
#' of the row's rating from the average rating in its neighborhood
#' will be applied to each group separately. For example we can add a column mean_neighbourhood_rating
#' which will be the mean rating in the row's group.
listings %>%
    group_by(neighbourhood_cleansed) %>%
    mutate(
        avg_neighb_rating = mean(review_scores_rating, na.rm = T),
        delta_avg_rating = review_scores_rating - mean(review_scores_rating, na.rm = T)
    ) %>% 
    select(id, neighbourhood_cleansed, review_scores_rating, avg_neighb_rating, delta_avg_rating)


#' The same is true of filter. Let's filter to those rows where the rating is above the neighborhood's 
#' average rating: 
listings %>% 
    select(id, neighbourhood_cleansed, review_scores_rating) %>% 
    group_by(neighbourhood_cleansed) %>%
    mutate(avg_neighb_rating = mean(review_scores_rating, na.rm = T)) %>% 
    filter(review_scores_rating > mean(review_scores_rating)) %>%
    select(id, review_scores_rating, avg_neighb_rating)

#' Oh no, there are no rows - why?!?!?!? Because we forgot to add `na.rm = T`. The result 
#' of `mean(review_scores_rating)` was `NA` for all groups, so no rows were technically above the mean of `NA`. 
#' *MORAL* `filter()` will automatically remove rows where the truth value is NA. This works instead:
listings %>% 
    select(id, neighbourhood_cleansed, review_scores_rating) %>% 
    group_by(neighbourhood_cleansed) %>%
    mutate(avg_neighb_rating = mean(review_scores_rating, na.rm = T)) %>% 
    filter(review_scores_rating > mean(review_scores_rating, na.rm = T)) %>%
    select(id, review_scores_rating, avg_neighb_rating)

#' Grouped `filter` and `mutate` are especially useful when used with `ranking` or `window` functions. 
#' For example, we can get the rank of each listing's rating within the neighbourhood:
listings %>% 
    select(id, neighbourhood_cleansed, review_scores_rating) %>% 
    group_by(neighbourhood_cleansed) %>%
    mutate(neighb_rank = min_rank(desc(review_scores_rating))) 


#' Useful ranking functions.
#'     `row_number()` which row is this in the group
#'     `min_rank(column)` the rank of the observation within its group
#'     `percent_rank(column)` the percentile rank of the observation within its group
#'     `ntile(column, integer)` a rough rank, which buckets the observations into <integer> groups and 

#' -----------------------------------------------------
#' EXERCISE 1: Help, `min_rank()` can't break ties!
#' -----------------------------------------------------
#' Oh no! You've realized that there are many listings with a `review_scores_rating` of 100 in 
#' each neighborhood, so there are many there's more than one rank == 1 everywhere: 
listings %>% 
    select(id, neighbourhood_cleansed, review_scores_rating) %>% 
    group_by(neighbourhood_cleansed) %>%
    mutate(neighb_rank = min_rank(desc(review_scores_rating))) %>%
    arrange(neighb_rank)


#' You decide you want to break ties by `review_scores_cleanliness`. Unfortunately, this does not work:
listings %>% 
    select(id, neighbourhood_cleansed, review_scores_rating, review_scores_cleanliness) %>% 
    group_by(neighbourhood_cleansed) %>%
    mutate(neighb_rank = min_rank(
        desc(review_scores_rating), 
        desc(review_scores_cleanliness)
    ))


#' Can you think of a way to get the listing's overall `review_scores_rating` rank within its 
#' neighborhood, breaking ties by `review_scores_cleanliness`?
#' Hint: you might want to think about `row_number()`

#' ----------------------------------------------
#' SOLUTION
#' ----------------------------------------------



#' ----------------------------------------------
#' WARNING
#' ----------------------------------------------
#' When you `group_by() %>% mutate/filter`, any function you use will be called once for every group, 
#' which creates a lot of overhead, especially if there are many groups. It is thus good practice
#' to `ungroup()` after you're done with groups so that future `mutate/filter` calls will not feel
#' the need to call functions more times than necessary (this is of course, only if you don't actually 
#' need them to do so). 
#' 
#' Consider the following toy example which is especially bad because date manipulation is 
#' computationally expensive: 

d1 = calendar %>% 
    group_by(listing_id) %>%
    # ... do stuff ... %>%
    filter(between(date, ymd(20191101), ymd(20191103)))

d2 = calendar %>% 
    group_by(listing_id) %>%
    # ... do stuff ... %>%
    ungroup %>% 
    filter(between(date, ymd(20191101), ymd(20191103)))

#' Both commands create the same exact data frame, because the filter result does not change
#' when you `group_by(listing_id)`. However `d1` took ~10 seconds to run, while `d2` was instantaneous. 
#' This is because the former needed to call `between` for each of the 6264 listings while the latter
#' used one big call. 


#' ----------------------------------------------
#' VARIABLE SELECTORS
#' ----------------------------------------------
#' The `tidyverse` offers a bunch of convenience functions to help you be lazy and avoid typing out
#' column names, which can be very useful when working with many columns. 

#' Suppose I want to look at all columns that are name `review_scores_<something>`. I could type 
#' them all out...
listings %>% select(
    name, 
    review_scores_rating,
    review_scores_accuracy, 
    review_scores_cleanliness, 
    review_scores_checkin, 
    review_scores_communication, 
    review_scores_location, 
    review_scores_value
)

#' Or I can use variable selectors to select columns based on their name:
#'    `starts_with`(string)
#'    `ends_with`(string)
#'    `contains`(string)
#'    `one_of`(many strings)
#'    `matches`(regex)
#'    `everything`()
#'    `last_col`(offset)


#' So with much less typing, I can do the same as above...
listings %>% select(name, starts_with("review_scores"))


#' You can also tell `select` to pick all but a certain set of columns by adding a `-`:
listings %>% select(-starts_with("host"))


#' Often you want to rearrange the order of columns for easier viewing. You can combine
#' selectors in any way: 
listings %>% 
    select(id, neighbourhood_cleansed, 
           starts_with("review_scores"), 
           everything())


#' Or suppose I want to move the last column that I just added with a mutate to the beginning:
listings %>% 
    mutate(mean_rating = mean(review_scores_rating, na.rm = T)) %>%
    select(id, last_col(), everything())


#' ----------------------------------------------
#' SCOPED VERBS: WORKING WITH MULTIPLE COLUMNS
#' ----------------------------------------------
#' Some of the most useful features of dplyr are the "scoped" versions of all the verbs¨
#'     `<verb>_all`(function):            apply function to all columns
#'     `<verb>_at`(variables, function):  apply function to variables selected as above. 
#'     `<verb>_if`(predicate, function):  apply to all columns that pass some test


#' Starting simple, let's find the mean of all `review_scores_xxx` columns by neighborhood.
#' We select first select all the relevant columns, and `group_by %>% summarise_all` to apply 
#' the mean function. 
listings %>%
    group_by(neighbourhood_cleansed) %>%
    select(starts_with("review_scores")) %>%      
    summarise_all(function(x) mean(x, na.rm = T))


#' Note that in all of the above cases, the function you want to apply must take only *one* argument, 
#' the the vector of column values. You can also add additional arguments to pass to the function: 
listings %>%
    group_by(neighbourhood_cleansed) %>%
    select(starts_with("review_scores")) %>%      
    summarise_all(mean, na.rm = T)


#' We can accomplish the same thing by using `summarise_at` without having to select out the 
#' relevant variables beforehand. Note that for `_at`() functions you need to wrap variable 
#' selectors in a `vars(...)` call. 
listings %>%
    group_by(neighbourhood_cleansed) %>% 
    summarise_at(
        vars(starts_with("review_scores")), 
        mean, na.rm = T
    )

#' Alternatively, you can give `_at()` a vector of column names, if you don't have an easy 
#' variable selector to use: 
listings %>%
    group_by(neighbourhood_cleansed) %>% 
    summarise_at(
        c("review_scores_rating", "review_scores_cleanliness"), # Note that there is no vars() in this case
        function(x) mean(x, na.rm=T)
    )


#' Let's now use `mutate_at()` to clean the price columns like Phil did for us last time. 
#' The `readr` has a wonderful function `parse_number()` that will take care of parsing the prices
#' for us
listings$price %>% parse_number() %>% head

#' We can now simply apply this function to all columns that contain "price" in their name
listings = listings %>% mutate_at(vars(contains("price")), parse_number)
calendar = calendar %>% mutate_at(vars(contains("price")), parse_number)


#' Another common use case is to apply a function to every column of a particular data type. 
#' `_if()` verbs are ideal for this: a *predicate* function, returning T/F is applied to each column to 
#' each column to decide if the second function should be applied to that column: 
listings %>% 
    mutate_if(is.Date, function(x) format(x, "%d %B %Y")) %>%
    select(name, last_scraped, host_since, calendar_last_scraped, first_review, last_review)


#' ----------------------------------------------
#' EXERCISE 2: Scoped filter
#' ----------------------------------------------
#' You and your friends won the Sloan *Innovation Is Not a Buzzword If You're Doing It*
#' entrepreneurship award, and have decided to spend the prize money on a long weekend
#' at one of the best AirBnBs in Boston. You're not yet sure how many days you'll be staying
#' or how many of you can make it, so you want to create an interactive dashboard that 
#' will tell you prices per night/person for some AirBnBs you like. 
#' 
#' Your first task is to find a list of candidate listings that meet your friend group's 
#' very stringent criteria. 
#' 
#' Use `filter_at()` to create a data frame of Boston's creme-de-la-creme of listings, i.e. 
#' those whose score is above their neighborhood's average *for every* `review_scores_xxx`. 
#' That is, the row should only be in the result if `review_scores_rating` is above its neighborhood's
#' average `review_scores_rating` AND `review_scores_cleanliness` is above its neighborhood's 
#' average `review_scores_rating` AND so forth and so fifth...
#' 
#' Name the result creme_de_la_creme. 
#' Hint: The result should have 1389 rows. 
#' 
#' ----------------------------------------------
#' SOLUTION
#' ----------------------------------------------





#' ----------------------------------------------
#' EXERCISE 3: Window functions
#' ----------------------------------------------
#' You've found your acceptable options, now you want to check their November availability 
#' in the calendar. For now let's assume you'll be staying just for two nights starting on a
#' Friday sometime in November. 
#' 
#' `lag()` and `lead()` are "window" functions that are particularly useful 
#' with time series data like the calendar data frame. 
#' 
#' Play around with the following to see what they do:
lag(c(1,2,3,4,5), 1)
lead(c(1,2,3,4,5), 2)
 
#' What you want from the calendar is, for every Friday in February, those `listing_id`s that are 
#' `available` on both that Friday AND the following day. Furthermore, the `minimum_nights` should 
#' be less than your planned 2 days, and the `maximum_nights` should be greater than  your planned 
#' 2 days. Finally, the output should also have a column for the `total_price` of that stay. 
#' 
#' The result should be called `avail` and should look like this: 
#' listing_id    date           total_price
#'      24240    2020-02-07             550     *24240 was available 11/01 and 11/02*
#'      24240    2020-02-14             550     *24240 was available 11/08 and 11/09*
#'       ...
#' 
#' 
#' All you  need is a combination of arrange(), group_by(), mutate()/filter() and lead(). 
#' Think: why is `arrange()` important when using lag/lead?
#' 
#' Hint: What will `df %>% group_by(...) %>% mutate(y = x + lead(x))` do? 
#' 
#' You may also find the following date functions useful: 
weekdays(ymd("2019-01-01"))
month(ymd("2019-01-01"), label=TRUE)

#' ----------------------------------------------
#' SOLUTION
#' ----------------------------------------------





#' Ok there's one small issue here: if we wanted a 5-day stay instead of a 2-day stay, 
#' typing out all the lead(...) calls would get painful real fast. 
#' 
#' There's some special packages that make "rolling" versions of functions easier (moving average, 
#' rolling sum etc) which could be helpful here. Another way to fix this will be through joins as we will 
#' see in just a bit. 

#' ----------------------------------------------
#' WARNING
#' ----------------------------------------------
#' When using `lag/lead`, make sure that the time series data is *COMPLETE*. 
#' In many cases, there might be implicit missing values, i.e. days where the row 
#' is ommitted (e.g. for product sales because there were no sales on that day). 
#' In that case, `lead(sales)` will give the value of sales in the next row, which might 
#' not be the next day as desired. 
#' 
#' Though we won't cover them here there are several function to help you convert
#' implicit missing rows to explicit NA rows, e.g. `complete()` or `crossing()`


#' ----------------------------------------------
#' CASE_WHEN
#' ----------------------------------------------
#' The `case_when()` function is very useful in mutate calls to encode if/elseif/else logic 
#' in a vectorized manner. Let's illustrate by formatting the date column to look like "November 3rd"
#' 
#' day(date) will give you which day of the month (e.g. 8 or 29) a date is. Depending on what the day 
#' of month is we want to add a suffix, e.g. "th" or "rd": 

avail %>%
    mutate(day_of_month = day(date), 
           suffix = case_when(
               day_of_month %in% c(11, 12, 13) ~ "th", 
               day_of_month %% 10 == 1         ~ "st", 
               day_of_month %% 10 == 2         ~ "nd", 
               day_of_month %% 10 == 3         ~ "rd", 
               TRUE                            ~ "th"
               ), 
           weekend_of = paste("Weekend of the ", day_of_month, suffix, sep = "")
    ) %>%
    select(-day_of_month, -suffix)


#' ----------------------------------------------
#' JOINING DATASETS
#' ----------------------------------------------
#' We now want to merge our two tables so that we have all the information in one place: what 
#' neighborhood the listing is in, how many it accomodates, what the prices will be etc. 
#' 
#' Let's go back to the slides to understand the different types of joins. 

#' And we're back... We can use a simple inner_join to get only the listings that are 
#' creme-de-la-creme and are available on a weekend in November: 
creme_de_la_creme = creme_de_la_creme %>% 
    select(id, neighbourhood_cleansed, property_type,
           accommodates, bedrooms, bathrooms, 
           latitude, longitude) # Picking out some columns

cdlc_feb = avail %>%
    inner_join(creme_de_la_creme, by = c("listing_id" = "id"))

#' ----------------------------------------------
#' EXERCISE 4: More complicated joining
#' ----------------------------------------------
#' Ok so in the original problem statement, you weren't actually sure how long your stay would be, 
#' yet we hard-coded the availability/pricing table to be only for two day stays. Recall that 
#' we had to state `filter(available, lead(available, 1))` and `adjusted_price + lead(adjusted_price,1)`. 
#' To do the same for a 3-day stay we would need to add `lead(available, 2)`, and so forth. 
#' Is there a smart way to make the length of the stay an "input" without having to hard-code it?
#' 
#' Let's walk through the steps of how you could accomplish this with a simple join: 
#' 
#' 1) Let's start off by creating a data frame of every creme-de-la-creme listing and Friday 
#' in November, and similar one for just the November/December calendar. The reason for this filtering
#' will become obvious in a bit. 
feb_weekends = calendar %>%
    semi_join(creme_de_la_creme, by = c("listing_id" = "id")) %>% 
    filter(year(date) == 2020, 
           month(date) == 2, 
           weekdays(date) == "Friday") %>%
    select(listing_id, date, minimum_nights, maximum_nights)

febmar_cal = calendar %>% 
    semi_join(creme_de_la_creme, by = c("listing_id" = "id")) %>% 
    filter(year(date) == 2020, 
           month(date) == 2 | month(date) == 3) %>%
    select(listing_id, date, available, adjusted_price)

#' 2) Now the trick: let's join the two on c("listing_id" = "listing_id"). 

avail_long = feb_weekends %>%
    left_join(febmar_cal, by = "listing_id") %>%
    rename(stay_start = date.x, stay_end = date.y) %>%
    mutate(diff_days = as.numeric(difftime(stay_end, stay_start, units = "days")))

#' Work with your partner on answering the following questions: 
#' - Can you interpret what the join did? 
#' - How is row duplication working to our advantage here?
#' - How many rows does each listing_id/stay_start combination have, and what
#'   are the stay_end/adjusted_price/available columns capturing in those rows?
#' - Harder question: why did we left join? Would some other type of join have worked equally well?
#' 
# ' I recommend looking at the table using View, and scrolling through a few hundred rows...
avail_long %>%
    arrange(listing_id, stay_start, stay_end) %>% 
    View
    

#' 3) Now here's the exercise: use a combination of `filter()`, `group_by()`, `summarise()` and
#' `filter` again to get the availability and price of all listings for an `ndays` long stay, where ndays is 
#' a variable you can change the value of. 
#' 
#' The output should be called `avail` as before, but now a row should only be there if: 
#'     - the listing was available for all `ndays` after the Friday
#'     - `ndays` (the input variable) is between the minimum and maximum stay on that Friday
#'     
#' To get you started I've written (one of many possible) series of verb calls you can use
#' to achieve this task. You'll need to fill in the actual commands.
#' 
#' For the `summarise` step you might want to check out what the following command does: 
#' all(c(TRUE, TRUE, TRUE, FALSE))

#' ----------------------------------------------
#' SOLUTION
#' ----------------------------------------------
ndays = 4



#' Here's what happened. When we joined on just `listing_id`, there were lots of cross-matches
#' and therefore row duplication. For example, the LHS row (3781, 2019-11-01) matched 61 rows on the RHS, 
#' i.e. all 61 Nov/Dec calendar days for that listing. LHS row (3781, 2019-11-08) also matched those rows, 
#' adding another 61 rows. 
#' 
#' The date on the LHS (which is one of the November Fridays) is a potential start date for our stay. 
#' The date on the RHS is a (potentially invalid) option for the stay's end. 
#' 
#' We could then treat these sets of 61 rows for each listing/stay start as groups, filtering to 
#' those within the appropriate number of days of the LHS date and summarising them to get the 
#' appropriate prices/availability. 
#' 
#' Of course, this comes at a cost: in joining we created an intermediate table with a lot more rows
#' (one for every matching combination). We tried to keep that number as low as possible by filtering
#' the LHS to Nov Fridays only and the RHS to Nov/Dec only, but that's still (5 Nov Fridays) * (61 days) = 
#' 305 rows per listing. If we hadn't filtered, we would have had (365 * 365)  rows per listing, which
#' would have been huge.


#' ----------------------------------------------
#' SYNTHESIS
#' ----------------------------------------------
#' Let's conclude the data wrangling session by setting up what we'll need for the visualization 
#' component. 
#' 
#' The last thing you need to know to plan your stay is how many people will be partaking in the 
#' festivities. There are some members of the team who are not sure they'll be able to make it
#' on some of the weekends, so you want `npeople` to also be an input that you can tweak, and look
#' at per person per day prices. 
#' 
#' So let's create a function that takes `ndays` and `npeople` as input and outputs a data frame
#' that we can use to make plots of valid listings. 
#' 
#' Specifically, the function will use the joining technique to filter to those listings that are 
#' fully available for an `ndays` stay (and meet the length of stay requirements). It will also 
#' provide the total price for that stay. Then it will join the cdlc to add information on the 
#' accomodations and computee per day/per person prices. 

get_availability_table = function(ndays, npeople){
    #' Filter and summarise `avail_long` to get available listings and total price
    #' for an `ndays` stay.
    avail = avail_long %>%
        filter(diff_days >= 0,
               diff_days < ndays, 
               ndays >= minimum_nights, 
               ndays <= maximum_nights) %>%
        group_by(listing_id, stay_start) %>%
        summarise(total_price = sum(adjusted_price), 
                  available_all = all(available)) %>%
        ungroup() %>%
        filter(available_all) %>%
        select(listing_id, stay_start, total_price) 
    
    #' Join to creme_de_la_creme to get overall info, filter to those that accomodate more than `npeople`. 
    #' Then calculate price per day per person. Recall that the join will also add columns like 
    #' accomodates, long, lat etc.
    avail = avail %>%
        inner_join(creme_de_la_creme, by = c("listing_id" = "id")) %>% 
        filter(accommodates > npeople) %>% 
        mutate(price_per_day_person = total_price / (ndays * npeople))
    
    return(avail)
}

# Let's check that this works:
avail = get_availability_table(4, 4) %>% select(1:8, last_col(), everything())

# And let's now make some histograms of prices. We'll filter to a specific 
# weekend:

avail %>%
    filter(stay_start == ymd(20200207)) %>%
    ggplot(aes(x = price_per_day_person)) + 
    geom_histogram()

# And with that, we have everything we need to build our bare-bones AirBnB app. 