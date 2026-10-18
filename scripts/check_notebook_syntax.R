# Parse fenced R chunks without executing any analysis or installing packages.
if (!dir.exists("code")) stop("Run from the repository root.")
rows <- list()
for (path in list.files("code", pattern = "\\.Rmd$", recursive = TRUE, full.names = TRUE)) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  in_r <- FALSE
  chunk <- character()
  start <- NA_integer_
  for (i in seq_along(lines)) {
    if (!in_r && grepl("^\\s*```\\{r([ ,}]|$)", lines[i])) {
      in_r <- TRUE
      start <- i
      chunk <- character()
    } else if (in_r && grepl("^\\s*```\\s*$", lines[i])) {
      issue <- tryCatch({ parse(text = chunk); "" }, error = function(e) conditionMessage(e))
      rows[[length(rows) + 1L]] <- data.frame(
        path = path, chunk_start_line = start,
        status = if (nzchar(issue)) "parse_error" else "ok", message = issue,
        stringsAsFactors = FALSE
      )
      in_r <- FALSE
    } else if (in_r) {
      chunk <- c(chunk, lines[i])
    }
  }
  if (in_r) rows[[length(rows) + 1L]] <- data.frame(
    path = path, chunk_start_line = start, status = "unclosed_fence",
    message = "R code fence has no closing fence", stringsAsFactors = FALSE)
}
checks <- do.call(rbind, rows)
write.csv(checks, file.path(tempdir(), "kora_notebook_syntax_checks.csv"), row.names = FALSE)
cat("Checked", nrow(checks), "R chunks in", length(unique(checks$path)), "notebooks.\n")
cat("Chunks requiring review:", sum(checks$status != "ok"), "\n")
if (any(checks$status != "ok")) print(checks[checks$status != "ok", c("path", "chunk_start_line", "message")], row.names = FALSE)
if (any(checks$status != "ok")) stop("Notebook syntax errors require review.")
