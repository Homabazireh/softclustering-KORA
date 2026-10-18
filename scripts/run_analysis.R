# Stage and run a notebook entirely in private storage, including figures/logs.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: Rscript scripts/run_analysis.R \"code/domain/notebook.Rmd\"")
repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(repo, "scripts", "preprocess_omics.R"))
Sys.setenv(KORA_CODE_DIR = repo)
private <- kora_private_root()
notebook <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
if (!startsWith(tolower(notebook), paste0(tolower(repo), "/code/")) ||
    !grepl("\\.Rmd$", notebook)) stop("Choose an Rmd inside this repository's code directory.")
if (!requireNamespace("knitr", quietly = TRUE)) stop("Install knitr first.")
run_dir <- file.path(private, "work")
dir.create(run_dir, showWarnings = FALSE, recursive = TRUE)
Sys.setenv(KORA_RUN_DIR = run_dir)
resolve_input <- function(file) {
  candidates <- c(file, file.path(run_dir, file),
                  file.path(private, "inputs", file),
                  file.path(private, "inputs", basename(file)),
                  file.path(private, "processed", file),
                  file.path(private, "processed", basename(file)))
  candidates <- candidates[file.exists(candidates)]
  if (!length(candidates)) stop("Required private input is missing; consult docs/inputs.md.")
  normalizePath(candidates[[1]], winslash = "/", mustWork = TRUE)
}
helpers <- new.env(parent = globalenv())
helpers$load <- function(file, envir = parent.frame(), ...) base::load(resolve_input(file), envir = envir, ...)
helpers$read.csv <- function(file, ...) utils::read.csv(resolve_input(file), ...)
helpers$read.csv2 <- function(file, ...) utils::read.csv2(resolve_input(file), ...)
helpers$readRDS <- function(file, ...) base::readRDS(resolve_input(file), ...)
env <- new.env(parent = helpers)
staged <- file.path(run_dir, basename(notebook))
file.copy(notebook, staged, overwrite = TRUE)
output <- file.path(run_dir, paste0(tools::file_path_sans_ext(basename(notebook)), ".md"))
log <- file.path(run_dir, paste0(tools::file_path_sans_ext(basename(notebook)), ".log"))
setwd(run_dir)
connection <- file(log, open = "wt")
sink(connection)
sink(connection, type = "message")
status <- tryCatch({
  knitr::opts_knit$set(root.dir = run_dir)
  knitr::opts_chunk$set(error = FALSE)
  lines <- readLines(staged, warn = FALSE, encoding = "UTF-8")
  lines <- gsub("error = TRUE", "error = FALSE", lines, fixed = TRUE)
  writeLines(lines, staged, useBytes = TRUE)
  knitr::knit(staged, output = output, envir = env, quiet = TRUE)
  TRUE
}, error = function(e) {
  cat(conditionMessage(e), "\n", file = stderr())
  FALSE
})
sink(type = "message")
sink()
close(connection)
if (!status) stop("Notebook stopped. Review the log in private storage; do not upload it.")
cat("Notebook completed. The report, log, figures, and outputs are in private storage.\n")
