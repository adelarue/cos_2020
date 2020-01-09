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

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Boston Airbnb"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            sliderInput("ndays", "Days", min=1, max=10, value=2, step=1),
            sliderInput("npeople", "People", min=1, max=10, value=3, step=1),
            dateInput("weekend_of", "Weekend of:", min=min(calendar $ date), 
                      max=max(calendar $ date), value=ymd(20200207))
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
    toplot <- reactive({
        get_availability_table(input $ ndays, input $ npeople) %>%
            filter(stay_start == input $ weekend_of)
    })
    
    output$distPlot <- renderPlot({
        toplot() %>% 
            ggplot(aes(x = price_per_day_person)) + 
            geom_histogram()
    })
    
    output $ map <- renderLeaflet({
        leaflet() %>%
            addTiles() %>% 
            addCircleMarkers(~ longitude, ~ latitude, data=toplot(),
                             popup=~ sprintf("%s ($%.2f)", name, price_per_day_person))
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
