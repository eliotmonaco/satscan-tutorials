# Get Essence data via API

library(Rnssp)
library(tidyverse)

# load Essence profile object, needed for `get_api_data()`
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
url <- build_ess_url(
  syndrome = ili,
  start = start_date,
  data_source = "patient",
  output = "dd",
  fields = c("Date", "ZipCode")
)

# Get data
dd <- get_api_data(
  url,
  fromCSV = TRUE,
  col_types = readr::cols(.default = "c")
)

colnames(dd) <- setmeup::fix_colnames(colnames(dd))

# Configure
dd <- dd |>
  mutate(date = as.Date(date, "%m/%d/%Y")) |>
  arrange(date, zip_code)

# Count ZIPs in KC
dd |>
  count(zip_code) |>
  mutate(in_kc = zip_code %in% unique(unlist(kcData::geoids$zcta))) |>
  count(in_kc)

# Count ZIPs per day
dd |>
  filter(zip_code %in% unique(unlist(kcData::geoids$zcta))) |>
  count(date, zip_code) |>
  arrange(desc(n))

# Save
saveRDS(dd, "data/1-source/essence_ili_by_patient_zip.rds")

