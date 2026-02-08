# Satscan tutorial 4: Ordinal scan statistic for identifying unusual cancer
# stage patterns

# https://www.satscan.org/tutorials/nyscolorectal/SaTScanTutorialNYSColorectal.pdf

library(rsatscan)
library(tidyverse)

dir_input <- "data/2-final/tutorial-4/"
dir.create(dir_input)

dir_output <- "output/tutorial-4/"
dir.create(dir_output)

nm <- "ny-colorectal-cancer"

# Import data file
cancer_data <- read.csv("data/1-source/colorectal_cancer.csv")

# Case file: <location ID> <# cases> <date/time> <attribute>
# Choose “group” for the location ID (representing the 952 grouped locations),
# “One Count” for the number of cases (meaning that each row is an individual
# case), and “stage” for the Attribute. We are not performing a temporal
# analysis, so leave Date/Time unassigned.
case_file <- cancer_data |>
  mutate(one_count = 1) |>
  select(group, one_count, stage)

write.cas(case_file, dir_input, nm)

# Coordinates file: <location ID> <latitude> <longitude>
geo_file <- cancer_data |>
  select(group, latitude, longitude)

write.geo(geo_file, dir_input, nm)

# Set Satscan options to defaults
invisible(ss.options(reset = TRUE, version = "10.3"))

# Set options for the analysis
ss.options(list(
  # Input
  CaseFile = paste0(dir_input, nm, ".cas"),
  PrecisionCaseTimes = "0", # none
  StartDate = "2010/01/01",
  EndDate = "2014/12/31",
  PopulationFile = paste0(dir_input, nm, ".pop"),
  CoordinatesFile = paste0(dir_input, nm, ".geo"),
  CoordinatesType = "1", # lat/long

  # Analysis
  AnalysisType = "1", # purely spatial
  ModelType = "3", # ordinal
  ScanAreas = "1", # high values

  # Output
  OutputGoogleEarthKML = "y",
  OutputShapefiles = "y",
  OutputCartesianGraph = "y",

  # Spatial Window
  MaxSpatialSizeInPopulationAtRisk = 10,

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

