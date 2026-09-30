# Changelog

## Unreleased

- Align the App Panel and adapter CLI with the completed canonical interface,
  including exact expression, metadata, and DEG input names and all allowed
  within-plot p-value adjustment choices.
- Keep canonical `output_dir` platform-owned as `/results`, remove the internal
  `deg_gene_column` UI field, and restore 6-by-5-inch image defaults.
- Keep `duplicate_aggregation` choices `mean`, `sum`, and `keep`, with `mean`
  as the default for normalized log-space expression.
- Move Code Ocean input helpers outside `code/functions/` so that directory is
  the exclusive byte-identical canonical scientific export.
- Add contract mutation, input/output, duplicate/missing-value, and visual
  regression checks while leaving platform and runtime-digest validation
  explicitly pending.
