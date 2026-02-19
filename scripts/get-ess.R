# Get Essence data via API

library(Rnssp)
library(tidyverse)
library(setmeup)

# Load Essence profile object, needed for `get_api_data()`
load("C:/Users/emonaco01/OneDrive - City of Kansas City/Documents/r/essence/myProfile.rda")

source("scripts/fn.R")

# Essence syndrome for API
ili = paste0(
  "medicalGroupingSystem=essencesyndromes&",
  "ccddCategory=ili%20ccdd%20v1"
)

# Start date = 1 year and 1 day before current date
start_date <- Sys.Date() - lubridate::years(1) - lubridate::days(1)

# Build API call

# url <- build_ess_url(
#   syndrome = ili,
#   start = start_date,
#   data_source = "patient",
#   output = "tb",
#   tb_col = "timeResolution",
#   tb_rows = "geographyzipcode",
#   zipcodes = TRUE
# )

flds <- c(
  "Date", "Time", "Age", "Sex", "DateOfBirth",
  "ZipCode", "Travel", "HospitalName", "VisitNumber",
  "Patient_ID", "MedicalRecordNumber"
)

url1 <- build_ess_url(
  syndrome = ili,
  start = start_date,
  data_source = "patient",
  output = "dd",
  dd_fields = flds
)

url2 <- build_ess_url(
  syndrome = ili,
  start = start_date,
  data_source = "hospital",
  output = "dd",
  dd_fields = flds
)

# Get data
ess1 <- get_api_data(
  url1,
  fromCSV = TRUE,
  col_types = readr::cols(.default = "c")
)

colnames(ess1) <- setmeup::fix_colnames(colnames(ess1))

ess2 <- get_api_data(
  url2,
  fromCSV = TRUE,
  col_types = readr::cols(.default = "c")
)

colnames(ess2) <- setmeup::fix_colnames(colnames(ess2))

# Run `config-ess.R` script on datasets
ess <- ess1

source("scripts/config-ess.R")

ess1_config <- ess; errors1 <- errors

ess <- ess2

source("scripts/config-ess.R")

ess2_config <- ess; errors2 <- errors

# Save
saveRDS(ess1, "data/1-source/ili_pat_raw.rds")
saveRDS(ess2, "data/1-source/ili_hosp_raw.rds")
saveRDS(ess1_config, "data/2-final/tutorial-6/ili_pat.rds")
saveRDS(ess2_config, "data/2-final/tutorial-6/ili_hosp.rds")
saveRDS(errors1, "data/2-final/tutorial-6/ili_pat_err.rds")
saveRDS(errors2, "data/2-final/tutorial-6/ili_hosp_err.rds")

