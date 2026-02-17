# Output Satscan options as a readable table
readable_opts <- function(opts) {
  # Get section names
  nms <- stringr::str_extract(
    opts[which(grepl("^\\[.*\\]$", opts))],
    "(?<=\\[).*(?=\\])"
  )

  # Get section indices
  x <- purrr::map2(
    which(grepl("^\\[.*\\]$", opts)) + 1,
    which(grepl("^$", opts)),
    \(x, y) seq(x, y)
  )

  # `opts` to list
  ls <- vctrs::vec_chop(opts, indices = x)

  names(ls) <- nms

  # Append an empty vector to each list element to create an even length
  ls <- lapply(ls, \(x) append(x, ""))

  # Vectors to dataframes
  df <- purrr::imap(ls, \(x, i) {
    evens <- x[seq_along(x) %% 2 == 0]

    odds <- x[seq_along(x) %% 2 == 1]

    data.frame(
      Section = i,
      Option = evens,
      Description = stringr::str_remove(odds, "^;")
    ) |>
      dplyr::mutate(Section = dplyr::if_else(
        Option == "" & Description == "",
        "",
        Section
      ))
  }) |>
    purrr::list_rbind()

  # Drop empty final rows
  df[1:max(which(df$Section != "")), ]
}

# Add a sheet with data formatted as a table to an Excel workbook
add_opts_to_xl <- function(wb, df, sheet_name = NULL) {
  if (is.null(sheet_name)) {
    sheet_name <- openxlsx2::next_sheet()
  }

  wb |>
    openxlsx2::wb_add_worksheet(sheet = sheet_name) |>
    openxlsx2::wb_add_data_table(
      x = df,
      table_style = "TableStyleMedium16"
    ) |>
    openxlsx2::wb_set_col_widths(
      cols = 1:3,
      widths = c(30, 50, 100)
    ) |>
    openxlsx2::wb_add_cell_style(
      dims = openxlsx2::wb_dims(
        rows = 1:nrow(df),
        cols = 1:ncol(df)
      ),
      wrap_text = "1"
    )
}

# Build URL for Essence API
build_ess_url <- function(
  syndrome, # list of syndromes built as in `syndromes.R`
  start, # start date (YYYY-MM-DD)
  end = Sys.Date(), # end date (YYYY-MM-DD)
  data_source = c("hospital", "patient"), # Data by hospital or patient location
  output = c("ts", "dd"), # ts = time series, dd = data details
  fields = NULL # if output is "dd", add desired fields here as character vector
) {
  start <- as.Date(start); end <- as.Date(end)

  if (is.na(start) | is.na(end)) {
    stop("`start` and `end` must be valid dates formatted YYYY-MM-DD")
  }

  data_source <- match.arg(data_source)

  output <- match.arg(output)

  # Output parameters
  if (output == "ts") {
    op <- "timeSeries?"

    params_out <- "aqtTarget=TimeSeries"
  } else if (output == "dd") {
    if (is.null(fields)) {
      stop("When `output` is \"dd\", `fields` cannot be empty")
    }

    op <- "dataDetails/csv?"

    fields <- paste0("field=", c(fields, "EssenceID", "C_BioSense_ID"))

    params_out <- paste(
      c("aqtTarget=DataDetails", fields),
      collapse = "&"
    )
  }

  # Data source parameters
  if (data_source == "hospital") {
    params_ds <- paste(
      "datasource=va_hosp",
      "geographySystem=hospital",
      "geography=mochildrensmercyercc",
      "geography=mochildrensmercynorthlandercc",
      "geography=moresearchkcercc",
      "geography=mostlukeskcercc",
      "geography=mostlukesnorthlandkcercc",
      "geography=motrumanhospitalhillercc",
      "geography=motrumanlakewoodercc",
      "geography=mostjosephkcercc",
      sep = "&"
    )
  } else if (data_source == "patient") {
    params_ds <- paste(
      "datasource=va_er",
      "geographySystem=region",
      "geography=mo_clay",
      "geography=mo_jackson",
      "geography=mo_platte",
      sep = "&"
    )
  }

  # Additional parameters
  params_add <- paste(
    "userId=5809",
    paste0("startDate=", format(start, "%d%b%Y")),
    paste0("endDate=", format(end, "%d%b%Y")),
    "percentParam=noPercent",
    "detector=probrepswitch",
    "timeResolution=daily",
    sep = "&"
  )

  params <- paste(
    params_out,
    params_ds,
    params_add,
    sep = "&"
  )

  endpoint <- "https://moessence.inductivehealth.com/ih_essence/api/"

  paste0(
    endpoint,
    op,
    paste0(params, "&", syndrome)
  )
}
