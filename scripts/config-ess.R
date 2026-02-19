# Configure Essence data

# Assign row ID
ess <- ess |>
  mutate(row_id = row_number(), .before = 1)

# Find "exact" duplicates
dupes <- find_dupes(ess, c(
  "date", "time", "age", "sex", "date_of_birth",
  "zip_code", "travel", "hospital_name",
  "visit_number"
))

# Remove dupes
ess <- ess |>
  anti_join(dupes, by = "row_id")

# Deduplicate using `visit_number`
dupes <- find_dupes(ess, "visit_number")

# If members of a dupe set have the same `patient_id`, `date`, and `zip_code`,
# all but one are redundant. Only one from each set will be kept in `ess`.
ls <- lapply(unique(dupes$dupe_id), \(x) {
  df <- dupes |> # filter a single dupe set
    filter(dupe_id == x)

  if (all(
    length(df$patient_id) == 1,
    length(df$date) == 1,
    length(df$zip_code) == 1
  )) {
    df[2:nrow(df), ] # redundant dupes to remove
  }
}) |>
  compact()

# Remove redundant dupes
if (length(ls) > 0) {
  ess <- ess |> # remove redundant dupes from `ess`
    anti_join(ls, by = "row_id")

  dupes <- dupes |> # remove redundant dupe sets from `dupes`
    filter(!dupe_id %in% unique(ls$dupe_id))
}

# Among the remaining dupe sets, if they are indeed duplicates, it isn't
# possible to determine which records have the correct date or ZIP code, both of
# which are needed for the spatiotemporal analysis. Therefore, all records will
# be kept. The potential error rate for both date and ZIP code will be noted.

# Find the number of duplicate sets with different values for each variable
diffs <- lapply(unique(dupes$dupe_id), \(x) {
  df <- dupes |> # filter a single dupe set
    filter(dupe_id == x)

  apply(df, 2, \(c) { # find the number of unique values for each variable
    length(unique(c))
  }) |>
    as.list() |>
    data.frame() |>
    mutate(
      n_dupes = nrow(df),
      n_potential_errors = n_dupes - 1 # count the number of potential errors
    )                                  # presuming that one value (date or ZIP)
}) |>                                  # is the correct one
  list_rbind()

# Replace values > 1 with the number of potential errors. If the value is 1,
# no potential errors are counted because the single value is presumed correct.
errors <- diffs |>
  mutate(across(
    -c(n_dupes, n_potential_errors),
    ~ ifelse(.x > 1, n_potential_errors, NA)
  )) |>
  select(-c(row_id, dupe_id, n_dupes, n_potential_errors))

# Sum the potential errors for each variable
errors <- colSums(errors, na.rm = TRUE) |>
  as_tibble(rownames = "var") |>
  rename(n = value) |>
  mutate(error_rate = n / nrow(ess))

# Configure
ess <- ess |>
  mutate(date = as.Date(date, "%m/%d/%Y"))

