# Satscan tutorial 2: Bernoulli spatial scan statistic for birth defect data

# https://www.satscan.org/tutorials/nysbirthdefect/SaTScanTutorialNYSBirthDefect.pdf

library(rsatscan)
library(tidyverse)

dir_input <- "data/2-final/tutorial-2/"
dir.create(dir_input)

dir_output <- "output/tutorial-2/"
dir.create(dir_output)

nm <- "ny-birth-defects"

# Import data file
bd_data <- foreign::read.dbf(
  "data/1-source/Birth_defects/Birth_defects.dbf"
)

# Case file: <location ID> <# cases> <date/time> <covariate 1> ...
case_file <- bd_data |>
  select(ZIP, DEFECT, YEAR)

write.cas(case_file, dir_input, nm)

# Control file: <location ID> <controls> <date/time> <covariate 1> ...
control_file <- bd_data |>
  select(ZIP, NODEFECT, YEAR)

write.ctl(control_file, dir_input, nm)

# Coordinates file: <location ID> <latitude> <longitude>
geo_file <- bd_data |>
  select(ZIP, LATITUDE, LONGITUDE)

write.geo(geo_file, dir_input, nm)

# Set Satscan options to defaults
invisible(ss.options(reset = TRUE, version = "10.3"))

# Set options for the analysis
ss.options(list(
  # Input
  CaseFile = paste0(dir_input, nm, ".cas"),
  PrecisionCaseTimes = "1", # year
  StartDate = "2005/01/01",
  EndDate = "2005/12/31",
  ControlFile = paste0(dir_input, nm, ".ctl"),
  CoordinatesFile = paste0(dir_input, nm, ".geo"),
  CoordinatesType = "1", # lat/long

  # Analysis
  AnalysisType = "1", # purely spatial
  ModelType = "1", # Bernoulli
  ScanAreas = "3", # high or low rates

  # Output
  OutputGoogleEarthKML = "y",
  OutputShapefiles = "y",
  OutputCartesianGraph = "y",

  # Spatial Window
  MaxSpatialSizeInPopulationAtRisk = 25,

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
  ssbatchfilename = "SaTScanBatch64"
)

# Get summary
summary(ssresults)

# Save main results file
writeLines(ssresults$main, paste0(dir_output, nm, ".txt"))

# Save results
saveRDS(ssresults, paste0(dir_input, gsub("-", "_", nm), ".rds"))

