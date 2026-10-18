# Synthetic-only functional checks; generated fixtures never enter Git.
source("scripts/preprocess_omics.R")
fixture <- tempfile("kora-synthetic-")
dir.create(fixture)
set.seed(23)
prot <- as.data.frame(matrix(0, nrow = 12, ncol = 1022))
names(prot) <- c(paste0("meta", seq_len(180)), paste0("sp__synthetic_", seq_len(842)))
prot[[1]] <- c(rep("FF4", 10), rep("OTHER", 2))
names(prot)[1] <- "Cohort"
prot[[3]] <- paste0("synthetic-protein-", seq_len(12))
for (i in 181:1022) prot[[i]] <- seq_len(12)
prot[10, 181] <- 1000
prot[9, 182] <- NA_real_
input <- file.path(fixture, "proteins.csv")
write.csv(prot, input, row.names = FALSE)
got <- preprocess_proteomics(input, file.path(fixture, "prot-out"))
stopifnot(nrow(got) == 9, ncol(got) == 843,
          got[got[[1]] == "synthetic-protein-10", 2] == median(c(1:9, 1000)),
          !"synthetic-protein-9" %in% got[[1]],
          !"synthetic-protein-11" %in% got[[1]])
env <- new.env()
load(file.path(fixture, "prot-out", "Scaled.log.Trans.Proteomics.RData"), envir = env)
stopifnot(identical(got, env$Scaled.log.Trans.Proteomics))
met <- as.data.frame(matrix(seq_len(6 * 433), nrow = 6, ncol = 433))
met[[3]] <- paste0("synthetic-metabolite-", seq_len(6))
input <- file.path(fixture, "metabolites.csv")
write.csv(met, input, row.names = FALSE)
exclusions <- file.path(fixture, "exclusions.csv")
write.csv(data.frame(row_index = c(2L, 5L)), exclusions, row.names = FALSE)
got <- preprocess_metabolomics(input, exclusions, file.path(fixture, "met-out"))
expected <- met[-c(2, 5), c(3, 46:433), drop = FALSE]
stopifnot(identical(unname(as.matrix(got)), unname(as.matrix(expected))))
load(file.path(fixture, "met-out", "Scaled.log.Trans.Metabolomics.RData"), envir = env)
stopifnot(identical(got, env$Scaled.log.Trans.Metabolomics))
expect_error <- function(expr) stopifnot(inherits(tryCatch({ force(expr); NULL }, error = identity), "error"))
expect_error(preprocess_metabolomics(input, "absent-private-config.csv", fixture))
write.csv(data.frame(row_index = 9999), exclusions, row.names = FALSE)
expect_error(preprocess_metabolomics(input, exclusions, fixture))
met[[3]][2] <- met[[3]][1]
write.csv(met, input, row.names = FALSE)
expect_error(preprocess_metabolomics(input, exclusions, fixture))
Sys.setenv(KORA_CODE_DIR = normalizePath(getwd(), winslash = "/"), KORA_PRIVATE_DIR = getwd())
expect_error(kora_private_root())
if (requireNamespace("knitr", quietly = TRUE)) {
  runner_private <- file.path(fixture, "runner-private")
  dir.create(file.path(runner_private, "inputs"), recursive = TRUE)
  dir.create(file.path(runner_private, "config"))
  file.copy(file.path(fixture, "proteins.csv"), file.path(runner_private, "inputs", "Proteomics.csv"))
  met[[3]] <- paste0("synthetic-metabolite-", seq_len(nrow(met)))
  write.csv(met, file.path(runner_private, "inputs", "metabolites_p500.csv"), row.names = FALSE)
  write.csv(data.frame(row_index = c(2L, 5L)), file.path(runner_private, "config", "metabolomics_exclusions.csv"), row.names = FALSE)
  Sys.setenv(KORA_PRIVATE_DIR = runner_private)
  binary <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
  for (domain in c("proteomics", "metabolomics")) {
    path <- paste0("code/", domain, "/Preprocessing_", domain, ".Rmd")
    result <- system2(binary, c("--vanilla", "scripts/run_analysis.R", shQuote(path)), stdout = TRUE, stderr = TRUE)
    if (!is.null(attr(result, "status"))) stop("Synthetic notebook runner failed; inspect its private temporary log.")
    stopifnot(file.exists(file.path(runner_private, "work", paste0("Preprocessing_", domain, ".md"))))
  }
  cat("Both preprocessing notebooks completed through the private runner.\n")
}
cat("Synthetic preprocessing checks passed. No study data were loaded.\n")
