readable_opts <- function(opts) {
  # Get section names
  nms <- stringr::str_extract(
    opts[which(grepl("^\\[.*\\]$", opts))],
    "(?<=\\[).*(?=\\])"
  )

  # Get section indices
  x <- purrr::map2(
    which(grepl("^\\[.*\\]$", opts)) + 1,
    which(grepl("^$", opts)) - 1,
    \(x, y) seq(x, y)
  )

  # `opts` to list
  ls <- vctrs::vec_chop(opts, indices = x)

  names(ls) <- nms

  # Vectors to dataframes
  purrr::imap(ls, \(x, i) {
    evens <- x[seq_along(x) %% 2 == 0]

    odds <- x[seq_along(x) %% 2 == 1]

    data.frame(
      Section = i,
      Option = evens,
      Description = stringr::str_remove(odds, "^;")
    )
  }) |>
    purrr::list_rbind()
}
