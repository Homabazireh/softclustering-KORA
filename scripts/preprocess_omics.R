# Core preprocessing extracted from the original project notebooks.
# Inputs already have the study provider's upstream transformations.
kora_private_root <- function() {
  path <- Sys.getenv("KORA_PRIVATE_DIR")
  if (!nzchar(path) || !dir.exists(path)) stop("Set KORA_PRIVATE_DIR to an existing private directory.")
  root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  repo <- Sys.getenv("KORA_CODE_DIR")
  if (nzchar(repo)) {
    repo <- normalizePath(repo, winslash = "/", mustWork = TRUE)
    if (tolower(root) == tolower(repo) || startsWith(tolower(root), paste0(tolower(repo), "/"))) {
      stop("KORA_PRIVATE_DIR must be outside the code repository.")
    }
  }
  root
}
validate_numeric_features <- function(data, columns) {
  if (!all(vapply(data[columns], is.numeric, logical(1)))) stop("Feature columns must be numeric.")
  if (any(vapply(data[columns], function(x) any(is.infinite(x)), logical(1)))) stop("Infinite feature values found.")
}
validate_ids <- function(ids) {
  if (anyNA(ids) || any(!nzchar(trimws(as.character(ids)))) || anyDuplicated(ids)) {
    stop("Sample identifiers must be present and unique; resolve privately before preprocessing.")
  }
}
preprocess_proteomics <- function(input, output_dir) {
  data <- utils::read.csv(input, check.names = FALSE, stringsAsFactors = FALSE)
  if (!"Cohort" %in% names(data) || ncol(data) != 1022L) {
    stop("Expected the original proteomics layout: Cohort and 1022 columns. Review a changed export before use.")
  }
  data <- data[!is.na(data$Cohort) & data$Cohort == "FF4", , drop = FALSE]
  if (!nrow(data)) stop("No FF4 samples found.")
  feature_columns <- 181:1022
  if (!all(grepl("^(sp|tr)_", names(data)[feature_columns]))) {
    stop("Columns 181:1022 must be protein features; metadata must not be treated as measurements.")
  }
  validate_numeric_features(data, feature_columns)
  if (any(vapply(data[feature_columns], function(x) all(is.na(x)), logical(1)))) stop("All-missing protein feature.")
  # Original rule: values at or outside 1.5 IQR fences become the median.
  for (column in feature_columns) {
    x <- data[[column]]
    q <- stats::quantile(x, c(0.25, 0.75), na.rm = TRUE)
    spread <- q[2] - q[1]
    outside <- which(x <= q[1] - 1.5 * spread | x >= q[2] + 1.5 * spread)
    x[outside] <- stats::median(x, na.rm = TRUE)
    data[[column]] <- x
  }
  Scaled.log.Trans.Proteomics <- stats::na.omit(data[, c(3, feature_columns), drop = FALSE])
  if (!nrow(Scaled.log.Trans.Proteomics)) stop("No complete proteomics samples remain.")
  validate_ids(Scaled.log.Trans.Proteomics[[1]])
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  save(Scaled.log.Trans.Proteomics, file = file.path(output_dir, "Scaled.log.Trans.Proteomics.RData"))
  utils::write.csv(Scaled.log.Trans.Proteomics, file.path(output_dir, "Scaled.log.Trans.Proteomics.csv"), row.names = FALSE)
  invisible(Scaled.log.Trans.Proteomics)
}
preprocess_metabolomics <- function(input, exclusions, output_dir) {
  data <- utils::read.csv(input, check.names = FALSE, stringsAsFactors = FALSE)
  if (ncol(data) != 433L) stop("Expected the original P500 layout with 433 columns; review changed exports.")
  validate_numeric_features(data, 46:433)
  # The source notebook's diagnostic median replacement edits a different
  # object and never propagates to its exported matrix; preserve that output.
  cleaned <- data[, c(3, 46:433), drop = FALSE]
  validate_ids(cleaned[[1]])
  if (!file.exists(exclusions)) stop("Provide the authorized private metabolomics_exclusions.csv, including a header even if no rows are excluded.")
  excluded <- utils::read.csv(exclusions, stringsAsFactors = FALSE)
  if (!identical(names(excluded), "row_index")) stop("Exclusions must have exactly one column named row_index.")
  rows <- excluded$row_index
  if (length(rows) && (!is.numeric(rows) || anyNA(rows) || any(rows != as.integer(rows)) ||
                       any(rows < 1L | rows > nrow(cleaned)) || anyDuplicated(rows))) {
    stop("Invalid private exclusion rows; indices must refer to the original input order.")
  }
  if (length(rows)) cleaned <- cleaned[-as.integer(rows), , drop = FALSE]
  if (!nrow(cleaned) || anyNA(cleaned)) stop("Metabolomics output must be nonempty and complete; review upstream input.")
  Scaled.log.Trans.Metabolomics <- cleaned
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  save(Scaled.log.Trans.Metabolomics, file = file.path(output_dir, "Scaled.log.Trans.Metabolomics.RData"))
  utils::write.csv(Scaled.log.Trans.Metabolomics, file.path(output_dir, "Scaled.log.Trans.Metabolomics.csv"), row.names = FALSE)
  invisible(Scaled.log.Trans.Metabolomics)
}
run_preprocessing <- function(modality) {
  root <- kora_private_root()
  out <- file.path(root, "processed")
  if (identical(modality, "proteomics")) {
    preprocess_proteomics(file.path(root, "inputs", "Proteomics.csv"), out)
  } else if (identical(modality, "metabolomics")) {
    preprocess_metabolomics(file.path(root, "inputs", "metabolites_p500.csv"),
                           file.path(root, "config", "metabolomics_exclusions.csv"), out)
  } else stop("Choose proteomics or metabolomics.")
  cat("Preprocessing completed. Outputs were written to private storage.\n")
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1L) stop("Usage: Rscript scripts/preprocess_omics.R proteomics|metabolomics")
  Sys.setenv(KORA_CODE_DIR = normalizePath(getwd(), winslash = "/"))
  run_preprocessing(args[[1]])
}
