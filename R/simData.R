
# Generate Spatial Datasets -----------------------------------------------

library(terra)
library(dplyr)
library(sf)
library(stars)


# Suitability
env <- rast("./pollinationSim/data/env.tif")
precip <- env$gsp
temp <- env$bio1
var <- env$bio7

mm <- minmax(precip)
precip_norm <- (precip - mm[[1]])/(mm[[2]] - mm[[1]])

mm <- minmax(temp)
temp_norm <- (temp - mm[[1]])/(mm[[2]] - mm[[1]])

mm <- minmax(var)
var_norm <- (var - mm[[1]])/(mm[[2]] - mm[[1]])

pollination_services <- terra::aggregate(
  weighted.mean(c(precip_norm, temp_norm, var_norm), c(0.2,0.3,1)),
  fact = 8, na.rm = TRUE)

plot(pollination_services)

# writeRaster(pollination_services, "./pollinationSim/data/services_baseline.tif")


# Pesticide use
pesticide_use <- readr::read_tsv(url("https://water.usgs.gov/nawqa/pnsp/usage/maps/county-level/PesticideUseEstimates/EPest.county.estimates.2010.txt"))
pesticides_nys <- pesticide_use[pesticide_use$STATE_FIPS_CODE == "36",] |>
  dplyr::group_by(COUNTY_FIPS_CODE) |>
  dplyr::summarise(kg = sum(EPEST_HIGH_KG)) |>
  dplyr::mutate(FIPS_CODE = paste0("36", COUNTY_FIPS_CODE)) |>
  dplyr::distinct(COUNTY_FIPS_CODE, .keep_all = TRUE)

counties <- st_read("./pollinationSim/data/nys_counties.gpkg")
pesticides_county <- merge(counties, pesticides_nys) |>
  mutate(kgPerArea = kg/CALC_SQ_MI)
pesticides_unitarea <- rast(stars::st_rasterize(pesticides_county["kgPerArea"]))
pesticides_unitarea[is.na(pesticides_unitarea)] <- 0

pesticide <- terra::project(pesticides_unitarea, pollination_services, method = "cubicspline") |>
  mask(pollination_services)

mm <- minmax(pesticide)
pesticide_norm <- (pesticide - mm[[1]])/(mm[[2]] - mm[[1]])

# writeRaster(pesticide_norm, "./pollinationSim/data/pesticides_baseline.tif", overwrite = TRUE)

# Agricultural Areas
crops <- rast("./pollinationSim/data/CDL_2010_36.tif")

alfalfa <- crops
values(alfalfa)[values(alfalfa) != 36] <- 0
alfalfa <- terra::project(alfalfa, pollination_services, method = "max") |>
  mask(pollination_services)
alfalfa <- subst(alfalfa, 36, 1)

apples <- crops
values(apples)[values(apples) != 68] <- 0
apples <- terra::project(apples, pollination_services, method = "max") |>
  mask(pollination_services)
apples <- subst(apples, 68, 1)

corn <- crops
values(corn)[!values(corn) %in% c(1,12)] <- 0
corn <- terra::project(corn, pollination_services, method = "max") |>
  mask(pollination_services)
corn <- subst(corn, 12, 1)

blueberries <- crops
values(blueberries)[values(blueberries) != 242] <- 0
blueberries <- terra::project(blueberries, pollination_services, method = "max") |>
  mask(pollination_services)
blueberries <- subst(blueberries, 242, 1)

nys_crops <- c(alfalfa, apples, corn, blueberries)
names(nys_crops) <- c("alfalfa", "apples", "corn", "blueberries")

# writeRaster(nys_crops, "./pollinationSim/data/crops.tif", overwrite = TRUE)


# Vectorize for geopandas -------------------------------------------------

# pollination_services
ps <- st_as_sf(st_as_stars(pollination_services))
st_write(ps, "./pollinationSim/data/data.gpkg", "baseServices")

# pesticide_norm
pn <- st_as_sf(st_as_stars(pesticide_norm))
st_write(pn, "./pollinationSim/data/data.gpkg", "basePesticides", append = TRUE)

# nys_crops
nc <- st_as_sf(st_as_stars(nys_crops))
st_write(nc, "./pollinationSim/data/data.gpkg", "cropLocations", append = TRUE)
