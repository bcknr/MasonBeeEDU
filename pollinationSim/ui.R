#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(bslib)

fluidPage(
  theme="simplex.min.css",
  tags$style(type="text/css",
             "label {font-size: 12px;}",
             ".recalculating {opacity: 1.0;}"
  ),

  tags$h2("Module 10: simulating pollination services under global change"),
  p("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
  hr(),

  fluidRow(
    column(8, "MAIN PLOT",
           plotOutput("mainPlot")),
    column(4,
           # Climate Change Scenario
           selectInput("richness","Diversity of Bees",
                       choices = c("Low",
                                   "Medium",
                                   "High")),
           selectInput("ssp", "Climate Change Scenario",
                       choices = c("Optimistic",
                                   "Pessimistic")),
           sliderInput("pesticide", "Pesticide Pressure:",
                       min = 0.01, max = 1, value = 0.5),
           sliderInput("spring_vuln", "Spring Bee Climate Vulnerability:",
                       min = 0.01, max = 1, value = 1),
           sliderInput("bumble_vuln",
                       "Buzz PollinatingSse Bee Climate Vulnerability:",
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

