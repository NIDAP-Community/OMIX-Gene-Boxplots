# Code Ocean-specific input discovery for OMIX Gene Boxplots.

find_unique_data_file <- function(data_root = "/data", label, pattern) {
  if (!dir.exists(data_root)) {
    stop("ERROR: `", data_root, "` is unavailable; upload the required file explicitly")
  }
  files <- list.files(
    data_root,
    recursive = TRUE,
    full.names = TRUE,
    pattern = "\\.(csv|tsv|txt|rds)$",
    ignore.case = TRUE
  )
  files <- files[file.info(files)$isdir %in% FALSE]
  files <- files[grepl(pattern, basename(files), ignore.case = TRUE, perl = TRUE)]
  files <- unique(normalizePath(files, mustWork = FALSE))
  if (!length(files)) {
    stop(
      "ERROR: No ", label, " was found under ", data_root, ". ",
      "Upload it explicitly or attach a data asset with a filename matching /", pattern, "/."
    )
  }
  if (length(files) != 1L) {
    stop(
      "ERROR: Multiple ", label, " candidates were found. Upload the intended file explicitly: ",
      paste(files, collapse = ", ")
    )
  }
  files[[1L]]
}

resolve_gene_column <- function(table, requested, label) {
  if (requested %in% names(table)) {
    return(requested)
  }
  # `GeneName` is the OMIX default. If an input uses a common alternate
  # identifier name, use it only when the caller left that default unchanged.
  if (identical(requested, "GeneName")) {
    candidates <- c("GeneName", "Gene Symbols", "GeneSymbol", "Gene")
    matched <- candidates[candidates %in% names(table)]
    if (length(matched)) {
      message(
        "Auto-detected gene identifier column for ", label, ": '",
        matched[[1L]], "'"
      )
      return(matched[[1L]])
    }
  }
  stop(
    "ERROR: `", label, "` is missing the requested gene identifier column '",
    requested, "'. Available columns: ", paste(names(table), collapse = ", ")
  )
}
