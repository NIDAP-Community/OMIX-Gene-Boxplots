#!/usr/bin/env Rscript

test_args <- commandArgs(FALSE)
test_file <- sub("^--file=", "", test_args[grepl("^--file=", test_args)])
adapter_dir <- normalizePath(file.path(dirname(test_file), ".."))
fixture_dir <- file.path(adapter_dir, "tests", "fixtures")

source(file.path(adapter_dir, "code", "functions", "OMIX_Gene_Boxplots.R"))

expression <- utils::read.csv(
  file.path(fixture_dir, "duplicate-expression.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
metadata <- utils::read.csv(
  file.path(fixture_dir, "duplicate-metadata.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

check_expected <- function(method, expected_file) {
  observed <- omix_aggregate_duplicate_genes(
    expression_table = expression,
    sample_metadata = metadata,
    gene_column = "GeneName",
    sample_column = "Sample",
    duplicate_aggregation = method
  )
  expected <- utils::read.csv(
    file.path(fixture_dir, expected_file),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = "NA"
  )
  for (index in seq_len(nrow(expected))) {
    observed_row <- observed[observed$GeneName == expected$gene[[index]], , drop = FALSE]
    stopifnot(nrow(observed_row) == 1L)
    observed_value <- observed_row[[expected$sample[[index]]]][[1L]]
    expected_value <- expected$value[[index]]
    if (is.na(expected_value)) {
      stopifnot(is.na(observed_value))
    } else {
      stopifnot(isTRUE(all.equal(observed_value, expected_value)))
    }
  }
  invisible(observed)
}

# The public adapter wrapper must default to mean for normalized log-space
# expression, while retaining explicit compatibility choices.
default_choices <- eval(formals(omix_gene_boxplots)$duplicate_aggregation)
stopifnot(identical(default_choices, c("mean", "sum", "keep")))

averaged <- check_expected("mean", "duplicate-expected-mean-long.csv")
summed <- check_expected("sum", "duplicate-expected-summed-long.csv")
kept <- omix_aggregate_duplicate_genes(
  expression_table = expression,
  sample_metadata = metadata,
  gene_column = "GeneName",
  sample_column = "Sample",
  duplicate_aggregation = "keep"
)
stopifnot(identical(kept, expression))
stopifnot(nrow(averaged) == 3L, nrow(summed) == 3L, nrow(kept) == 5L)

# Exercise the complete exported wrapper so the fixture proves that the
# adapter's default, legacy compatibility mode, and keep mode reach the plotted
# long-form data and run summary—not only the aggregation helper.
device_file <- tempfile("gene-boxplots-adapter-", fileext = ".pdf")
grDevices::pdf(device_file)
on.exit({
  invisible(grDevices::dev.off())
  unlink(device_file)
}, add = TRUE)

run_wrapper <- function(method = NULL) {
  output_dir <- tempfile(paste0("gene-boxplots-", method %||% "default", "-"))
  arguments <- list(
    expression_table = expression,
    sample_metadata = metadata,
    genes = "GeneDup",
    statistics_mode = "none",
    minimum_samples_per_category = 2L,
    output_dir = output_dir,
    image_dpi = 72L
  )
  if (!is.null(method)) arguments$duplicate_aggregation <- method
  result <- do.call(omix_gene_boxplots, arguments)
  stopifnot(file.exists(file.path(output_dir, "gene_boxplots", "GeneDup.png")))
  summary <- utils::read.csv(
    file.path(output_dir, "gene_boxplot_run_summary.csv"),
    stringsAsFactors = FALSE
  )
  stopifnot(identical(summary$duplicate_aggregation[[1L]], method %||% "mean"))
  unlink(output_dir, recursive = TRUE)
  result
}

`%||%` <- function(left, right) if (is.null(left)) right else left
wrapper_default <- run_wrapper()
wrapper_sum <- run_wrapper("sum")
wrapper_keep <- run_wrapper("keep")
stopifnot(
  identical(wrapper_default$duplicate_aggregation, "mean"),
  identical(wrapper_sum$duplicate_aggregation, "sum"),
  identical(wrapper_keep$duplicate_aggregation, "keep"),
  nrow(wrapper_default$data) == 4L,
  nrow(wrapper_sum$data) == 4L,
  nrow(wrapper_keep$data) == 8L
)
stopifnot(isTRUE(all.equal(
  sort(wrapper_default$data$value),
  c(1, 1.75, 2.25, 3),
  check.attributes = FALSE
)))
stopifnot(isTRUE(all.equal(
  sort(wrapper_sum$data$value),
  c(2, 3.5, 4.5, 6),
  check.attributes = FALSE
)))

# The deployment panel and entry point must expose and forward the same three
# canonical choices without silently changing the default.
panel <- jsonlite::fromJSON(
  file.path(adapter_dir, ".codeocean", "app-panel.json"),
  simplifyVector = FALSE
)
panel_parameter <- Filter(
  function(parameter) identical(parameter$id, "duplicate_aggregation"),
  panel$parameters
)
stopifnot(length(panel_parameter) == 1L)
panel_parameter <- panel_parameter[[1L]]
stopifnot(
  identical(panel_parameter$param_name, "duplicate_aggregation"),
  identical(panel_parameter$default_value, "mean"),
  identical(unlist(panel_parameter$extra_data), c("mean", "sum", "keep"))
)

main_text <- paste(readLines(file.path(adapter_dir, "code", "main.R")), collapse = "\n")
stopifnot(grepl('"--duplicate_aggregation"', main_text, fixed = TRUE))
stopifnot(grepl("duplicate_aggregation = opt\\$duplicate_aggregation", main_text))

message("Gene Boxplots adapter duplicate aggregation checks passed")
