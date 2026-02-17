# Satscan tutorial 5: Multinomial scan statistic for identifying unusual
# population age structures

# https://www.satscan.org/tutorials/unusualpopulationage/SaTScanUnusualPopulationAge.pdf

library(rsatscan)
library(tidyverse)

dir_input <- "data/2-final/tutorial-5/"
dir.create(dir_input)

dir_output <- "output/tutorial-5/"
dir.create(dir_output)

nm <- "us-pop-age-structure"

# Import data files
case_file <- read.csv(
  "data/1-source/USCensusData2010/population_by_age.cas",
  header = FALSE,
  col.names = c("location", "fips", "population", "age_group"),
  colClasses = c("character", "character", "numeric", "numeric")
)

geo_file <- read.csv(
  "data/1-source/USCensusData2010/Coordinates.geo",
  header = FALSE,
  col.names = c("fips", "lat", "long"),
  colClasses = c("character", "numeric", "numeric")
)

# Case file: <location ID> <# cases> <date/time> <attribute>
case_file <- case_file |>
  select(fips, population, age_group)

write.cas(case_file, dir_input, nm)

# Coordinates file: <location ID> <latitude> <longitude>
write.geo(geo_file, dir_input, nm)

# Set Satscan options to defaults
invisible(ss.options(reset = TRUE, version = "10.3"))

# Set options for the analysis
ss.options(list(
  # Input
  CaseFile = paste0(dir_input, nm, ".cas"),
  PrecisionCaseTimes = "0", # none
  StartDate = "2010/04/15",
  EndDate = "2010/04/15",
  CoordinatesFile = paste0(dir_input, nm, ".geo"),
  CoordinatesType = "1", # lat/long

  # Analysis
  AnalysisType = "1", # purely spatial
  ModelType = "7", # multinomial
  ScanAreas = "1", # NA for multinomial model

  # Output
  OutputGoogleEarthKML = "y",
  OutputShapefiles = "y",
  OutputCartesianGraph = "y",

  # Spatial Window
  MaxSpatialSizeInPopulationAtRisk = 5,

  # Inference
  MonteCarloReps = 999,

  # Spatial Output
  ReportHierarchicalClusters = "y",
  CriteriaForReportingSecondaryClusters = 0, # NoGeoOverlap
  ReportGiniClusters = "n"
))

write.ss.prm(dir_output, nm)

# Run Satscan
ssresults <- satscan(
  prmlocation = dir_output,
  prmfilename = nm,
  sslocation = "C:/Program Files/SaTScan",
  ssbatchfilename = "SaTScanBatch64",
  verbose = TRUE
)

# Get summary
summary(ssresults)

# Save main results file
writeLines(ssresults$main, paste0(dir_output, nm, ".txt"))

# Save results
saveRDS(ssresults, paste0(dir_input, gsub("-", "_", nm), ".rds"))

