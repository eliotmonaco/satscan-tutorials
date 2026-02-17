# Compare Satscan options from rsatscan, the Satscan program, and the tutorial 6
# parameter file

library(tidyverse)
library(rsatscan)
library(openxlsx2)

source("scripts/fn.R")

# Get rsatscan options
opts_pkg <- ss.options(reset = TRUE, version = "10.3")

# Get Satscan program options
opts_app <- readLines("data/1-source/satscan-default-params-v10-3-3.prm")

# Get tutorial 6 options
opts_tut <- readLines("data/1-source/SpaceTimePermutation_sample_parameter_file.prm")

# Restructure each to dataframe
opts_pkg <- readable_opts(opts_pkg)
opts_app <- readable_opts(opts_app)
opts_tut <- readable_opts(opts_tut)

# Get option names (remove "=" and following text)
nm1 <- str_remove(opts_pkg$Option, "=.*$")
nm1 <- nm1[!grepl("^$", nm1)]

nm2 <- str_remove(opts_app$Option, "=.*$")
nm2 <- nm2[!grepl("^$", nm2)]

nm3 <- str_remove(opts_tut$Option, "=.*$")
nm3 <- nm3[!grepl("^$", nm3)]

# Find option names unique to sets
nm1[!nm1 %in% nm2]
nm2[!nm2 %in% nm1]

nm1[!nm1 %in% nm3]
nm3[!nm3 %in% nm1]

nm2[!nm2 %in% nm3]
nm3[!nm3 %in% nm2]

# Isolate tutorial options different from the rsatscan defaults
opts_tut_unq <- opts_tut |>
  anti_join(
    opts_pkg |>
      mutate(Option = if_else(Option == "", NA, Option)),
    by = "Option"
  )

# Filter out unimportant options
opts_tut_unq <- opts_tut_unq |>
  filter(!grepl("^Email|-Source|^Version=", Option))

# Remove extra blank rows
r <- which(opts_tut_unq$Section == "")

r <- r[which(diff(r) == 1) + 1]

opts_tut_unq[r, ]

df <- opts_tut_unq[-r, ]

df <- df[1:max(which(df$Section != "")), ]

# Create Excel workbook
wb <- wb_workbook()

wb <- wb |>
  add_opts_to_xl(opts_tut, "All options") |>
  add_opts_to_xl(df, "Non-default options")

wb$open()

wb_save(wb, "output/tutorial-6/satscan-options-tutorial-6.xlsx")
