# Create a spreadsheet with readable Satscan options

library(openxlsx2)
library("rsatscan")

source("scripts/fn.R")

# Get default options
opts <- ss.options(reset = TRUE, version="10.3")

# Restructure to dataframe
opts <- readable_opts(opts)

# Create Excel workbook
wb <- wb_workbook()

wb <- wb |>
  wb_add_worksheet() |>
  wb_add_data_table(
    x = opts,
    table_style = "TableStyleMedium16"
  ) |>
  wb_set_col_widths(
    cols = 1:3,
    widths = c(30, 50, 100)
  ) |>
  wb_add_cell_style(
    dims = wb_dims(rows = 1:nrow(opts), cols = 1:ncol(opts)),
    wrap_text = "1"
  )

wb$open()

wb_save(wb, "output/satscan-options.xlsx")
