#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-workflow-input.R")
}
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))
source(file.path(repo_root, "code", "functions", "OMIX_Gene_Boxplots.R"))

fixture <- tempfile("gene-boxplots-workflow-")
data_root <- file.path(fixture, "data")
workflow_dir <- file.path(data_root, "workflow-result")
metadata_dir <- file.path(data_root, "metadata")
dir.create(workflow_dir, recursive = TRUE)
dir.create(metadata_dir, recursive = TRUE)
on.exit(unlink(fixture, recursive = TRUE), add = TRUE)

expression <- data.frame(
  GeneName = "GeneA",
  A1 = 3.1, A2 = 3.3, B1 = 6.1, B2 = 5.9,
  `B-A_pval` = 0.001, `B-A_adjpval` = 0.002,
  check.names = FALSE
)
metadata <- data.frame(
  Sample = c("A1", "A2", "B1", "B2"),
  Group = c("A", "A", "B", "B"),
  stringsAsFactors = FALSE
)
write.csv(expression, file.path(workflow_dir, "DEG_Analysis.csv"), row.names = FALSE)
write.csv(metadata, file.path(metadata_dir, "Sample_Metadata.csv"), row.names = FALSE)

files <- list.files(data_root, recursive = TRUE, full.names = TRUE, pattern = "\\.csv$")
deg_files <- files[tolower(basename(files)) == "deg_analysis.csv"]
metadata_files <- files[tolower(basename(files)) == "sample_metadata.csv"]
stopifnot(length(deg_files) == 1L, length(metadata_files) == 1L)

result <- omix_gene_boxplots(
  expression_table = utils::read.csv(deg_files[[1L]], check.names = FALSE),
  sample_metadata = utils::read.csv(metadata_files[[1L]], check.names = FALSE),
  genes = "GeneA",
  statistics_mode = "precomputed_deg",
  deg_results = utils::read.csv(deg_files[[1L]], check.names = FALSE)
)
stopifnot(nrow(result$statistics) == 1L)

message("OMIX Gene Boxplots workflow-input checks passed")
