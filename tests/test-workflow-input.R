#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) stop("Run this check with Rscript tests/test-workflow-input.R")
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))
source(file.path(repo_root, "code", "functions", "OMIX_Gene_Boxplots.R"))
source(file.path(repo_root, "code", "adapter_io.R"))

stopifnot(file.exists(file.path(repo_root, "code", "functions", "Boxplot_with_Stats.R")))
stopifnot(exists("gene_boxplot_with_deg_results", mode = "function"))

fixture <- tempfile("gene-boxplots-workflow-")
data_root <- file.path(fixture, "data")
workflow_dir <- file.path(data_root, "workflow-result")
metadata_dir <- file.path(data_root, "metadata")
dir.create(workflow_dir, recursive = TRUE)
dir.create(metadata_dir, recursive = TRUE)
on.exit(unlink(fixture, recursive = TRUE), add = TRUE)

expression <- data.frame(
  Gene = "GeneA",
  A1 = 3.1, A2 = 3.3, A3 = 3.2, B1 = 6.1, B2 = 5.9, B3 = 6.2,
  `B-A_pval` = 0.001, `B-A_adjpval` = 0.002,
  check.names = FALSE
)
metadata <- data.frame(
  Sample = c("A1", "A2", "A3", "B1", "B2", "B3"),
  Group = c("A", "A", "A", "B", "B", "B"),
  stringsAsFactors = FALSE
)
write.csv(expression, file.path(workflow_dir, "DEG-Results.csv"), row.names = FALSE)
write.csv(metadata, file.path(metadata_dir, "Sample Metadata - Demo.csv"), row.names = FALSE)

deg_path <- find_unique_data_file(data_root, "DEG/expression table", "DEG")
metadata_path <- find_unique_data_file(data_root, "sample metadata table", "metadata")
stopifnot(identical(basename(deg_path), "DEG-Results.csv"))
stopifnot(identical(basename(metadata_path), "Sample Metadata - Demo.csv"))
stopifnot(identical(resolve_gene_column(expression, "GeneName", "expression_table"), "Gene"))
stopifnot(identical(read_table_file(deg_path, "expression table"), expression))

# The workflow binding targets the stable DEG table basename rather than every
# artifact containing "DEG" (for example, a run summary).
canonical_result_dir <- file.path(fixture, "canonical-result")
dir.create(canonical_result_dir)
write.csv(expression, file.path(canonical_result_dir, "DEG_Analysis.csv"), row.names = FALSE)
write.csv(expression, file.path(canonical_result_dir, "DEG_Analysis_run_summary.csv"), row.names = FALSE)
stopifnot(identical(
  basename(find_unique_data_file(
    canonical_result_dir,
    "DEG/expression table",
    "^DEG_Analysis\\.csv$"
  )),
  "DEG_Analysis.csv"
))

format_dir <- file.path(fixture, "formats")
dir.create(format_dir)
tsv_path <- file.path(format_dir, "expression.tsv")
rds_path <- file.path(format_dir, "expression.rds")
write.table(expression, tsv_path, sep = "\t", quote = FALSE, row.names = FALSE)
saveRDS(expression, rds_path)
stopifnot(
  identical(read_table_file(tsv_path, "expression table"), expression),
  identical(read_table_file(rds_path, "expression table"), expression)
)

# Explicit uploads always win over attached-data discovery. This keeps the
# three canonical file bindings deterministic even when /data has other files.
explicit_expression <- file.path(fixture, "explicit-expression.csv")
write.csv(expression, explicit_expression, row.names = FALSE)
stopifnot(identical(
  resolve_upload(explicit_expression, "expression table"),
  normalizePath(explicit_expression)
))

result <- omix_gene_boxplots(
  expression_table = utils::read.csv(deg_path, check.names = FALSE),
  sample_metadata = utils::read.csv(metadata_path, check.names = FALSE),
  genes = "GeneA",
  statistics_mode = "precomputed_deg",
  deg_results = utils::read.csv(deg_path, check.names = FALSE),
  gene_column = "Gene",
  deg_gene_column = "Gene"
)
stopifnot(nrow(result$statistics) == 1L)

write.csv(expression, file.path(workflow_dir, "second_DEG.csv"), row.names = FALSE)
error <- tryCatch({
  find_unique_data_file(data_root, "DEG/expression table", "DEG")
  NULL
}, error = identity)
stopifnot(inherits(error, "error"))
stopifnot(grepl("Multiple DEG/expression table candidates", conditionMessage(error), fixed = TRUE))

missing_error <- tryCatch({
  find_unique_data_file(file.path(fixture, "missing"), "DEG/expression table", "DEG")
  NULL
}, error = identity)
stopifnot(
  inherits(missing_error, "error"),
  grepl("is unavailable", conditionMessage(missing_error), fixed = TRUE)
)

message("OMIX Gene Boxplots workflow-input and legacy checks passed")
