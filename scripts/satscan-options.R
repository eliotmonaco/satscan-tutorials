# Create a spreadsheet with readable Satscan options

library(openxlsx2)
library(rsatscan)

source("scripts/fn.R")

# Get default options
opts <- ss.options(reset = TRUE, version = "10.3")

# Restructure to dataframe
opts <- readable_opts(opts)

# Create Excel workbook
wb <- wb_workbook()

wb <- wb |>
  add_opts_to_xl(opts)

wb$open()

wb_save(wb, "output/satscan-options.xlsx")
