#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- normalizePath(file.path(dirname(script), ".."))
source(file.path(root, "code", "functions", "OMIX_Gene_Boxplots.R"))

expression <- data.frame(
  GeneName = "GeneA",
  A1 = 1.0, A2 = 1.2, A3 = 0.8,
  B1 = 3.0, B2 = 3.1, B3 = 2.9,
  C1 = 5.0, C2 = 5.2, C3 = 4.8,
  `B-A_pval` = 0.020,
  `B-A_adjpval` = 0.040,
  `C-A_pval` = 0.001,
  `C-A_adjpval` = 0.003,
  `C-B_pval` = 0.030,
  `C-B_adjpval` = 0.050,
  check.names = FALSE
)
metadata <- data.frame(
  Sample = c("A1", "A2", "A3", "B1", "B2", "B3", "C1", "C2", "C3"),
  Group = rep(c("A", "B", "C"), each = 3L),
  stringsAsFactors = FALSE
)

output_dir <- tempfile("gene-boxplot-visual-")
on.exit(unlink(output_dir, recursive = TRUE, force = TRUE), add = TRUE)
result <- omix_gene_boxplots(
  expression_table = expression,
  sample_metadata = metadata,
  genes = "GeneA",
  statistics_mode = "precomputed_deg",
  deg_results = expression,
  pvalue_type = "nominal",
  output_dir = output_dir,
  image_width = 6,
  image_height = 5,
  image_dpi = 72L
)

plot <- result$plots[["GeneA"]]
stopifnot(inherits(plot, "ggplot"))

# Preserve the original CCBR visual grammar: lightly filled boxes, small
# points, original ordered palette, right-side legend, and black italic
# comparison annotations drawn as horizontal bars over the compared groups.
geom_names <- vapply(plot$layers, function(layer) class(layer$geom)[[1L]], character(1))
stopifnot(
  identical(geom_names[[1L]], "GeomBoxplot"),
  identical(plot$layers[[1L]]$aes_params$alpha, 0.3),
  identical(geom_names[[2L]], "GeomPoint"),
  identical(plot$layers[[2L]]$aes_params$size, 1),
  identical(plot$theme$legend.position, "right")
)

expected_colors <- c("#e41a1c", "#377eb8", "#4daf4a")
colour_scale <- Filter(
  function(scale) "colour" %in% scale$aesthetics,
  plot$scales$scales
)[[1L]]
stopifnot(identical(unname(colour_scale$palette(3L)[seq_len(3L)]), expected_colors))

segment_layers <- which(geom_names == "GeomSegment")
text_layers <- which(geom_names == "GeomText")
stopifnot(length(segment_layers) == 3L, length(text_layers) == 3L)
for (index in segment_layers) {
  stopifnot(identical(plot$layers[[index]]$aes_params$colour, "black"))
}
for (index in text_layers) {
  stopifnot(
    identical(plot$layers[[index]]$aes_params$colour, "black"),
    identical(plot$layers[[index]]$aes_params$fontface, "italic")
  )
}

built <- ggplot2::ggplot_build(plot)
for (index in segment_layers) {
  segment <- built$data[[index]]
  stopifnot(
    nrow(segment) == 1L,
    segment$x[[1L]] != segment$xend[[1L]],
    isTRUE(all.equal(segment$y[[1L]], segment$yend[[1L]]))
  )
}

stopifnot(isTRUE(all.equal(
  result$statistics$p_adj,
  c(0.020, 0.001, 0.030),
  check.attributes = FALSE
)))

adjusted_result <- omix_gene_boxplots(
  expression_table = expression,
  sample_metadata = metadata,
  genes = "GeneA",
  statistics_mode = "precomputed_deg",
  deg_results = expression,
  pvalue_type = "adjusted",
  output_dir = NULL
)
stopifnot(isTRUE(all.equal(
  adjusted_result$statistics$p_adj,
  c(0.040, 0.003, 0.050),
  check.attributes = FALSE
)))

# Render-level regression: an explicit 6x5-inch, 72-DPI export must be
# 432x360 pixels and retain visible pixels from each original group color and
# the black comparison annotations. This catches layer/theme changes that a
# table-only check cannot observe without committing a generated plot.
image_path <- file.path(output_dir, "gene_boxplots", "GeneA.png")
stopifnot(file.exists(image_path))
pixels <- png::readPNG(image_path)
stopifnot(identical(dim(pixels)[1:2], c(360L, 432L)))
rgb_pixels <- matrix(pixels[, , seq_len(3L), drop = FALSE], ncol = 3L)
near_color <- function(hex, tolerance = 0.08) {
  target <- as.numeric(grDevices::col2rgb(hex)) / 255
  sum(sqrt(rowSums((rgb_pixels - matrix(target, nrow(rgb_pixels), 3L, byrow = TRUE))^2)) < tolerance)
}
stopifnot(
  all(vapply(expected_colors, near_color, numeric(1)) > 0),
  near_color("#000000", tolerance = 0.05) > 0
)

message("Gene Boxplots visual regression checks passed")
