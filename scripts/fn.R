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
  output = c("dd", "tb", "ts"), # dd = data details, tb = table builder, ts = time series
  dd_fields = NULL, # if output is "dd", add desired fields here as character vector,
  tb_col = NULL,
  tb_rows = NULL,
  zipcodes = FALSE
) {
  start <- as.Date(start); end <- as.Date(end)

  if (is.na(start) | is.na(end)) {
    stop("`start` and `end` must be valid dates formatted YYYY-MM-DD")
  }

  data_source <- match.arg(data_source)

  output <- match.arg(output)

  # Output parameters
  if (output == "dd") {
    if (is.null(dd_fields)) {
      stop("When `output` is \"dd\", `dd_fields` cannot be empty")
    }

    op <- "dataDetails/csv?"

    dd_fields <- paste0("field=", c(dd_fields, "EssenceID"))

    params_out <- paste(
      c("aqtTarget=DataDetails", dd_fields),
      collapse = "&"
    )
  } else if (output == "tb") {
    op <- "tableBuilder/csv?"

    if (length("tb_col") > 1) {
      stop("`tb_col` must have length of 1")
    }

    if (is.null(tb_col) || is.null(tb_rows)) {
      stop("When `output` is \"tb\", `tb_col` and `tb_rows` cannot be empty")
    }

    params_out <- paste(
      "aqtTarget=TableBuilder",
      paste0("columnField=", tb_col),
      paste(paste0("rowFields=", tb_rows), collapse = "&"),
      sep = "&"
    )
  } else if (output == "ts") {
    op <- "timeSeries?"

    params_out <- "aqtTarget=TimeSeries"
  }

  # Data source & geography parameters
  if (data_source == "hospital") {
    params_ds <- "datasource=va_hosp"

    params_geo <- paste(
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
    params_ds <- "datasource=va_er"

    params_geo <- paste(
      "geographySystem=region",
      "geography=mo_clay",
      "geography=mo_jackson",
      "geography=mo_platte",
      sep = "&"
    )
  }

  # ZIP code free text
  if (zipcodes) {
    params_geo <- paste(
      "geographySystem=zipcode",
      paste0(
        "geography=",
        paste(sort(unique(unlist(
          kcData::geoids$zcta
        ))), collapse = ",")
      ),
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
    params_geo,
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
