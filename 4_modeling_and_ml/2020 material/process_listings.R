library(tidyverse)

process_listings <- function(path) {
  
  # Get raw data.
  listings_raw <- read.csv(path, stringsAsFactors = FALSE)
  
  # Process and select only relevant columns.
  listings <- listings_raw %>%
    
    # Parse price string.
    mutate(price = parse_number(price)) %>%
    
    # Get rid of some outliers.
    filter(accommodates <= 10, price <= 1000) %>%
    
    # Take only some property types and neighbourhoods.
    filter(property_type %in%
             c("Apartment", "House", "Bed & Breakfast", "Condominium", "Loft", "Townhouse"),
           !(neighbourhood_cleansed %in%
               c("Leather District", "Longwood Medical Area"))) %>%
    
    # Turn integer columns into doubles.
    mutate_if(is.integer, as.numeric) %>%
    
    # Impute missing data with column medians.
    mutate_all(~coalesce(., median(., na.rm = TRUE))) %>%
    
    # Take only the columns that we need.
    select(price, accommodates, review_scores_rating, property_type, neighbourhood_cleansed, room_type) %>%
    
    # Convert characters to factors.
    mutate_if(is.character, as.factor)
  
  return(listings)
}
