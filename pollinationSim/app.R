#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(bslib)
library(bsicons)

ui <- fluidPage(
  theme="simplex.min.css",
  tags$style(type="text/css",
             "label {font-size: 12px;}",
             ".recalculating {opacity: 1.0;}"
  ),

  tags$h2("Module 10: simulating pollination services under global change"),
  p("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
  hr(),

  fluidRow(
    column(8,
           span("MAIN PLOT",
                tooltip(
                  bs_icon("info-circle"),
                  "Simulated Pollination Services. Values closer to 1 have higher pollination services",
                  placement = "bottom")),
           plotOutput("mainPlot")),
    column(4,

           # Climate Change Scenario
           selectInput("rich","Diversity of Bees",
                       choices = c("Low",
                                   "Medium",
                                   "High")),
           selectInput("ssp", "Climate Change Scenario",
                       choices = c("Optimistic", # SSP1
                                   "Middle of the Road", # SSP2
                                   "Pessimistic")), # SSP5
           sliderInput("pesticide", "Pesticide Pressure:",
                       min = 0.01, max = 1, value = 0.5),
           sliderInput("spring_vuln", "Spring Bee Climate Vulnerability:",
                       min = 0.01, max = 1, value = 1),
           sliderInput("bumble_vuln",
                       "Bumble Bee Climate Vulnerability:",
                       min = 0.01, max = 1, value = 1)
    )
  ),

  fluidRow(
    column(4,
           h4("Pollination Services"),
           plotOutput("servPlot")),
    column(4,
           h4("Pollination Table"),
           tableOutput("pollinTable")),
    column(4,
           h4("Curves"),
           plotOutput("curvsPlot"))
  )
)


# Define server logic required to draw a histogram
server <- function(input, output) {

  # Simulate pollination services
  ####
  sliderValues <- reactive({
    data.frame(
      Name = c("e", "c_s"),
      Value = c(input$pesticide,
                input$spring_vuln)
    )
  })

  # alpha <-  7.5 + 7.5 * (sliderValues$e)
  # beta <-  7.5 + 7.5 * (1 - (c - e))

  alpha <- runif(100)

  output$mainPlot <- renderPlot({

    #' Map of pollination services (10km resolution)
    #' layer 1: 0-1 pollination services
    #' layer 2: map of selected crop varieties

    hist(alpha, col = 'darkgray', border = 'orange',
         xlab = 'Waiting time to next eruption (in mins)')
  })

  output$servPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    # x    <- runif(100)

    # draw the histogram with the specified number of bins
    hist(alpha, col = 'darkgray', border = 'orange',
         xlab = 'Waiting time to next eruption (in mins)',
         main = 'Histogram of waiting times')
  })

  output$pollinTable <- renderTable({
    sliderValues()
  })

  output$curvsPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    # x    <- sort(runif(100))

    # draw the histogram with the specified number of bins
    plot(alpha, type = "l", col = 'darkgray',
         xlab = 'Waiting time to next eruption (in mins)',
         main = 'Histogram of waiting times')
  })

}

# Run the application
shinyApp(ui = ui, server = server)
