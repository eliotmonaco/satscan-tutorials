# Satscan tutorial 6: Prospective spatiotemporal cluster detection

# https://publichealth.jmir.org/2024/1/e50653

library(rsatscan)
library(tidyverse)
library(sf)

dir_input <- "data/2-final/tutorial-6/"
dir.create(dir_input)

dir_output <- "output/tutorial-6/"
dir.create(dir_output)

nm <- "kc-ili"

# Import data files
ess_data <- readRDS("data/1-source/essence_ili_by_patient_zip.rds")
kc_zctas <- readRDS("data/1-source/kc_zctas.rds")

# Case file: <location ID> <# cases> <date/time> <attribute>
case_file <- ess_data |>
  filter(
    zip_code %in% unique(unlist(kcData::geoids$zcta)), # zip codes in KC only
    date < Sys.Date() # most recent date with complete data
  ) |>
  count(zip_code, date) |>
  select(zip_code, n, date)

write.cas(case_file, dir_input, nm)

# Coordinates file: <location ID> <latitude> <longitude>
geo_file <- kc_zctas |>
  st_drop_geometry() |>
  select(ZCTA5CE20) |>
  bind_cols( # get centroid coordinates for each zcta
    kc_zctas |>
      st_centroid() |>
      st_coordinates()
  ) |>
  select(ZCTA5CE20, Y, X)

write.geo(geo_file, dir_input, nm)

# Set Satscan options to defaults
invisible(ss.options(reset = TRUE, version = "10.3"))

date_min <- format(min(case_file$date), "%Y/%m/%d")
date_max <- format(max(case_file$date), "%Y/%m/%d")

# Set options for the analysis
ss.options(list(
  # Input
  CaseFile = paste0(dir_input, nm, ".cas"),
  PrecisionCaseTimes = 3, # day
  StartDate = date_min,
  EndDate = date_max,
  CoordinatesFile = paste0(dir_input, nm, ".geo"),
  CoordinatesType = 1, # lat/long

  # Analysis
  AnalysisType = 4, # prospective spacetime
  ModelType = 2, # spacetime permutation
  ScanAreas = 1, # high rates
  TimeAggregationUnits = 3, # day

  # Output
  OutputGoogleEarthKML = "y",
  OutputShapefiles = "n",
  OutputCartesianGraph = "y",
  # MostLikelyClusterEachCentroidDBase = "n",
  # MostLikelyClusterCaseInfoEachCentroidDBase = "n",
  # CensusAreasReportedClustersDBase = "n",
  # IncludeRelativeRisksCensusAreasDBase = "n",

  # Data Checking
  StudyPeriodCheckType = 1, # relaxed bounds
  GeographicalCoordinatesCheckType = 1, # relaxed coordinates

  # # Locations network
  # LocationsNetworkFilename = "", # NETWORK FILE USED IN NYC STUDY
  # UseLocationsNetworkFile = "y",

  # Spatial Window
  MaxSpatialSizeInPopulationAtRisk = 50,

  # Temporal window
  MinimumTemporalClusterSize = 2, # 2 days
  MaxTemporalSizeInterpretation = 1, # interpret as time
  MaxTemporalSize = 30, # 30 days

  # Space and Time Adjustments
  AdjustForWeeklyTrends = "y",

  # Inference
  MonteCarloReps = 999,
  ProspectiveStartDate = "1900/01/01",

  # Cluster Drilldown
  DrilldownClusterCutoff = 0.05, # DIFFERENTLY WORDED - SAME PARAM?

  # Miscellaneous Analysis
  ProspectiveFrequencyType = 1, # daily

  # Spatial Output
  LaunchMapViewer = "n",
  CompressKMLtoKMZ = "y",
  IncludeClusterLocationsKML = "n",
  ReportHierarchicalClusters = "y",
  CriteriaForReportingSecondaryClusters = 1, # NoCentersInOther

  # Temporal output
  OutputTemporalGraphHTML = "y",
  TemporalGraphReportType = 2, # report only significant clusters
  TemporalGraphSignificanceCutoff = 0.01, # cluster p-value cutoff for reporting

  # # Other output # THESE PARAMS NOT AVAILABLE IN PKG OR APP OPTS
  # ClusterSignificanceByRecurrence = "y",
  # ClusterSignificanceRecurrenceCutoff = 100,
  # ClusterSignificanceRecurrenceCutoffType = 3,
  # ClusterSignificanceByPvalue = "n",
  # ClusterSignificancePvalueCutoff, = 0.05

  # Line list options in tutorial 6 params file not present in rsatscan or app

  # Run Options
  LogRunToHistoryFile = "n"
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





