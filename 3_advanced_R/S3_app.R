#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/

library(shiny)
library(leaflet)
library(lubridate)
source("shiny_prep.R")

##############################
######### A template ########
##############################

ui <- fluidPage()
server <- function(input, output){}
shinyApp(ui = ui, server = server)

###############################
##### Some widgets in Shiny ###
###############################

# Let's start by adding functionality 
# We will first define a simple interface 
ui <- fluidPage(
  verticalLayout(
    sliderInput("bins", "Number of bins:", min = 1, max = 50, value = 30),
    checkboxGroupInput("checkGroup", 
                       h3("Checkbox group"), 
                       choices = list("Choice 1" = 1, 
                                      "Choice 2" = 2, 
                                      "Choice 3" = 3),
                       selected = 1),
    actionButton("action", "Action"),
    plotOutput("distPlot")
  )
)
server <- function(input, output){}
shinyApp(ui = ui, server = server)

# For now we will just use the sliderInput button but there is a wide collection of these widgets available online.
# You can find them here: https://shiny.rstudio.com/gallery/widget-gallery.html
# Let's focus now on the Server. As we said before, Server is a function. It takes a list of inputs, processes them using reactives, and assigns the results to a list of outputs.

###############################
####### A simple example ######
###############################

ui <- fluidPage(
  verticalLayout(
    sliderInput("bins", "Number of bins:", min = 1, max = 50, value = 30),
    plotOutput("distPlot")
  )
)

server <- function(input, output){
  x    <- faithful[, 2]
  bins <- reactive({
    #Seq is a command that gives us a sequence of numbers with a defined min, max, and step.
    seq(min(x), max(x), length.out = input$bins + 1)
  })     
  output$distPlot <- renderPlot({
    hist(x, breaks = bins())
  })
}

shinyApp(ui = ui, server = server)

################################################
###### Let's go back to the Airbnb Example #####
################################################

# We will take it step by step.
# The first thing we need to do is define the user interface and provide the input of interest.

################################################
###### STEP 1: THE USER INTERFACE #####
################################################


# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Boston Airbnb"),
  
  # Sidebar with a slider input for number of bins 
  # Note that this is a different Layout.
  # It is structured on the side. 
  # Thus you will see that there is a sidebarPanel for the Input and a mainPanel for the output.
  sidebarLayout(
    sidebarPanel(
      #Provide the number of days for the stay
      sliderInput("ndays", "Days", min=1, max=10, value=2, step=1),
      #Provide the number of people in the group
      sliderInput("npeople", "People", min=1, max=10, value=3, step=1),
      #Provide the date
      dateInput("weekend_of", "Weekend of:", min=min(calendar $ date), 
                max=max(calendar $ date), value=ymd(20200214))
    ),
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("distPlot"),
      leafletOutput("map")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {}

# Run the application 
shinyApp(ui = ui, server = server)

################################################
###### STEP 2: ADD THE OUTPUT MAP #############
################################################

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Boston Airbnb"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      sliderInput("ndays", "Days", min=0, max=10, value=1, step=1),
      sliderInput("npeople", "People", min=1, max=10, value=1, step=1),
      dateInput("weekend_of", "Weekend of:", min=min(calendar $ date), 
                max=max(calendar $ date), value=ymd(20200214))
    ),
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("distPlot"),
      leafletOutput("map")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  # We need to get the availability table of all host sites based on the inputs.
  # Notice that due to the input dependency, this object is created into a reactive section.
  toplot <- reactive({
    get_availability_table(input $ ndays, input $ npeople) %>%
      filter(stay_start == input $ weekend_of)
  })
  
  #Similar to the previous example, in renderPlot we can use another object from a reactive section and output its values.
  #Here, we do it with a histogram
  output$distPlot <- renderPlot({
    toplot() %>% 
      ggplot(aes(x = price_per_day_person)) + 
      geom_histogram()
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)


################################################
###### STEP 3: GET THE FULL APP ################
################################################


# Define UI for application that draws a histogram
ui <- fluidPage(
  titlePanel("Boston Airbnb"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput("ndays", "Days", min=0, max=10, value=1, step=1),
      sliderInput("npeople", "People", min=1, max=10, value=1, step=1),
      dateInput("weekend_of", "Weekend of:", min=min(calendar $ date), 
                max=max(calendar $ date), value=ymd(20200214))
    ),
    mainPanel(
      plotOutput("distPlot"),
      leafletOutput("map")
    )
  )
)

server <- function(input, output) {
  toplot <- reactive({
    get_availability_table(input $ ndays, input $ npeople) %>%
      filter(stay_start == input $ weekend_of)
  })
  
  output$distPlot <- renderPlot({
    toplot() %>% 
      ggplot(aes(x = price_per_day_person)) + 
      geom_histogram()
  })
  
  # Let's create the interactive map.
  # The leaflet library will help us on that front.
  # We will use Circle Markers for each point (described by longitude and latitude).
  # The paste function will give us a combination of the apt's name and price per person.
  output $ map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>% 
      addCircleMarkers(~ longitude, ~ latitude, data=toplot(),
                       popup=~ paste0(name, " $", price_per_day_person))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

#Done! 

#######################
###### EXERCISE 1 #####
#######################

# Add an input that allows the user to filter on neighborhood 
# Tip: use listings $ neighborhood_cleansed to see what neighborhoods are in the dataset
# Tip: selectInput(...) will be useful

#######################
###### EXERCISE 2 #####
#######################

# Add an interactive table that displays information about the listings
# Tip: You will want to use renderDataTable(...) and dataTableOutput(...)

