#!/usr/bin/env Rscript

# OMIX Gene Boxplots — Code Ocean adapter
#
# User uploads take precedence. Without uploads, this adapter discovers exactly
# one upstream DEG result and exactly one metadata table below /data. The
# explicit ambiguity checks intentionally prevent a Pipeline from silently
# plotting the wrong input when several assets are attached.

suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  file_arg <- commandArgs(FALSE)[grepl("^--file=", commandArgs(FALSE))]
  if (!length(file_arg)) {
    return(getwd())
  }
  dirname(normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE))
}

runtime_root <- normalizePath(file.path(get_script_dir(), ".."), mustWork = TRUE)
source(file.path(runtime_root, "code", "functions", "OMIX_Gene_Boxplots.R"))
source(file.path(runtime_root, "code", "functions", "workflow_input.R"))

option_list <- list(
  make_option("--expression_file", type = "character", default = "", help = "Optional expression table upload"),
  make_option("--metadata_file", type = "character", default = "", help = "Optional sample metadata upload"),
  make_option("--deg_file", type = "character", default = "", help = "Optional DEG result upload"),
  make_option("--genes", type = "character", default = "", help = "Required comma-separated gene identifiers"),
  make_option("--gene_column", type = "character", default = "GeneName"),
  make_option("--deg_gene_column", type = "character", default = "GeneName"),
  make_option("--sample_column", type = "character", default = "Sample"),
  make_option("--category_column", type = "character", default = "Group"),
  make_option("--categories", type = "character", default = ""),
  make_option("--statistics_mode", type = "character", default = "precomputed_deg"),
  make_option("--pvalue_type", type = "character", default = "nominal"),
  make_option("--statistical_method", type = "character", default = "anova"),
  make_option("--p_adjust_method", type = "character", default = "BH"),
  make_option("--minimum_samples_per_category", type = "integer", default = 2L),
  make_option("--plot_type", type = "character", default = "box"),
  make_option("--plot_title_prefix", type = "character", default = "Expression: "),
  make_option("--y_axis_label", type = "character", default = "Expression"),
  make_option("--colors", type = "character", default = ""),
  make_option("--image_width", type = "double", default = 6),
  make_option("--image_height", type = "double", default = 5),
  make_option("--image_dpi", type = "integer", default = 300L)
)

# Code Ocean passes blank values as `--parameter ""`. Drop blank parameter
# pairs before optparse processes them.
args <- commandArgs(trailingOnly = TRUE)
filtered_args <- character()
index <- 1L
while (index <= length(args)) {
  if (args[[index]] == "") {
    index <- index + 1L
  } else if (index < length(args) && startsWith(args[[index]], "--") && args[[index + 1L]] == "") {
    index <- index + 2L
  } else {
    filtered_args <- c(filtered_args, args[[index]])
    index <- index + 1L
  }
}
opt <- parse_args(OptionParser(option_list = option_list), args = filtered_args)

read_table_file <- function(path, label) {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    stop("ERROR: `", label, "` was not found: ", path)
  }
  extension <- tolower(tools::file_ext(path))
  if (identical(extension, "rds")) {
    object <- readRDS(path)
    if (!is.data.frame(object)) {
      stop("ERROR: `", label, "` RDS must contain a data frame")
    }
    return(object)
  }
  if (identical(extension, "csv")) {
    return(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
  }
  utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
}

resolve_upload <- function(value, label) {
  if (!is.null(value) && nzchar(value)) {
    if (!file.exists(value)) {
      stop("ERROR: Uploaded ", label, " was not found: ", value)
    }
    return(normalizePath(value))
  }
  NULL
}

if (!nzchar(opt$genes)) {
  stop("ERROR: `--genes` is required. Enter one or more comma-separated gene identifiers.")
}
if (!opt$statistics_mode %in% c("precomputed_deg", "within_plot", "none")) {
  stop("ERROR: `--statistics_mode` must be precomputed_deg, within_plot, or none")
}
if (!opt$pvalue_type %in% c("nominal", "adjusted")) {
  stop("ERROR: `--pvalue_type` must be nominal or adjusted")
}

expression_path <- resolve_upload(opt$expression_file, "expression table")
metadata_path <- resolve_upload(opt$metadata_file, "sample metadata")
deg_path <- resolve_upload(opt$deg_file, "DEG results")

if (is.null(expression_path)) {
  expression_path <- if (!is.null(deg_path)) {
    deg_path
  } else {
    find_unique_data_file(
      label = "DEG/expression table",
      pattern = "DEG"
    )
  }
}
if (is.null(metadata_path)) {
  metadata_path <- find_unique_data_file(
    label = "sample metadata table",
    pattern = "metadata"
  )
}
if (identical(opt$statistics_mode, "precomputed_deg") && is.null(deg_path)) {
  deg_path <- expression_path
}

message("Expression table: ", expression_path)
message("Sample metadata: ", metadata_path)
if (!is.null(deg_path)) message("DEG table: ", deg_path)

result_dir <- if (dir.exists("/results")) "/results" else file.path(runtime_root, "results")
dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
expression_table <- read_table_file(expression_path, "expression_table")
metadata_table <- read_table_file(metadata_path, "metadata_table")
deg_table <- if (!is.null(deg_path)) read_table_file(deg_path, "deg_table") else NULL
expression_gene_column <- resolve_gene_column(
  expression_table, opt$gene_column, "expression_table"
)
deg_gene_column <- if (!is.null(deg_table)) {
  resolve_gene_column(deg_table, opt$deg_gene_column, "deg_table")
} else {
  opt$deg_gene_column
}
result <- omix_gene_boxplots(
  expression_table = expression_table,
  sample_metadata = metadata_table,
  genes = omix_parse_csv_values(opt$genes),
  gene_column = expression_gene_column,
  sample_column = opt$sample_column,
  category_column = opt$category_column,
  categories = opt$categories,
  statistics_mode = opt$statistics_mode,
  deg_results = deg_table,
  deg_gene_column = deg_gene_column,
  pvalue_type = opt$pvalue_type,
  statistical_method = opt$statistical_method,
  p_adjust_method = opt$p_adjust_method,
  minimum_samples_per_category = opt$minimum_samples_per_category,
  plot_type = opt$plot_type,
  plot_title_prefix = opt$plot_title_prefix,
  y_axis_label = opt$y_axis_label,
  colors = omix_parse_csv_values(opt$colors),
  output_dir = result_dir,
  image_width = opt$image_width,
  image_height = opt$image_height,
  image_dpi = opt$image_dpi
)
message(
  "Completed ", length(result$plots), " gene boxplot(s) with ",
  nrow(result$statistics), " statistical comparison(s). Results: ", result_dir
)
