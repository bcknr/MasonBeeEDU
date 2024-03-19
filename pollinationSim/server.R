
library(shiny)

paramNames <- c("richness", "ssp", "pesticide", "spring_vuln", "buzz_vuln")


sim_pollination <- function(richness = "High", ssp = "Optimistic",
                            pesticide = 0.5, spring_vuln = 0.5,
                            buzz_vuln = 0.5, prop_spring = 0.25,
                            prop_buzz = 0.5) {

  # Inputs
  spp_richness <- c(0.5,0.75,1)[c("Low", "Medium", "High") == richness]
  ssp <- c(1, 0.5)[c("Optimistic","Pessimistic") == ssp]
  exposure <- pesticide
  spring <- spring_vuln
  buzz <- buzz_vuln

  # Spatial Data
  service_base <- rast("data/services_baseline.tif") # 0 - 1, higher == more services
  pesticide_pressure <- rast("data/pesticides_baseline.tif") # 0 - 1, higher == greater pesticide use
  crops <- rast("data/crops.tif")

  # Adjust spatial data for richness, climate
  service_total <- service_base * spp_richness * ssp

  # Adjust for pesticides
  service_pesticide <- service_total * 1 - (pesticide_pressure * exposure)

  # Calculate spring and buzz pollination service
  service_spring <- service_pesticide * (prop_spring * (1 - spring))
  service_buzz <- service_pesticide * (prop_buzz * (1 - buzz))

  service <- c(service_pesticide, service_spring, service_buzz)
  names(service) <- c("total", "spring", "buzz")

  # Extract values in each crop's region
  focal_crops <- c("apples","blueberries","alfalfa","corn")

  service_crop <- list()
  for (i in seq_along(focal_crops)) {
    crop_locations <- values(crops[[i]])
    service_crop[[i]] <- values(service)[crop_locations == 1 & !is.na(crop_locations),]
  }

  names(service_crop) <- focal_crops

  return(list(total = service$total, pollination = service_crop, crop = crops))
}


function(input, output, session) {

  getParams <- function(prefix) {

    params <- lapply(paramNames, function(p) {
      input[[paste0(prefix, "_", p)]]
    })

    names(params) <- paramNames
    params
  }

  sim <- reactive(do.call(sim_pollination, getParams))

  output$mainPlot <- renderPlot({

    #' Map of pollination services (10km resolution)
    #' layer 1: 0-1 pollination services

    plot(sim())

  })

  output$servPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    # x    <- runif(100)

    # draw the histogram with the specified number of bins
    hist(runif(100), col = 'darkgray', border = 'orange',
         xlab = 'Waiting time to next eruption (in mins)',
         main = 'Histogram of waiting times')
  })

  output$pollinTable <- renderTable({
    # sliderValues()
  })

  output$curvsPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    # x    <- sort(runif(100))

    # draw the histogram with the specified number of bins
    plot(rnorm(100, mean = 1), type = "l", col = 'darkgray',
         xlab = 'Waiting time to next eruption (in mins)',
         main = 'Histogram of waiting times')
  })
}
