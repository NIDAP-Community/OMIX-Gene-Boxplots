# OMIX Gene Boxplots

Create one sample-level expression plot per selected gene, with optional
annotations from the same differential-expression model that produced the
results.

## Related repository

This repository is the **Code Ocean deployment adapter** for the canonical,
platform-neutral [OMIX Gene Boxplots module](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Gene-Boxplots).
The canonical OMIX module is the source of reusable scientific behavior. This
repository provides Code Ocean input discovery, App Panel configuration,
environment selection, and `/results` output.

## Recommended workflow use

For a result from **OMIX DEG Analysis**, use the exported
`DEG_Analysis.csv` as both the expression table and the precomputed DEG table.
It contains the normalized or batch-corrected sample-expression values together
with columns like `B-A_pval` and `B-A_adjpval`.

The plotter also needs matching sample metadata, because group labels are not
recoverable from an expression matrix alone. Attach a second Data Asset with
exactly one file named `Sample_Metadata.csv`, or upload it through the App
Panel. Its default required columns are `Sample` and `Group`.

When this capsule runs after an upstream DEG capsule in a Code Ocean Pipeline:

1. Connect the DEG Results output. The adapter discovers exactly one
   `DEG_Analysis.csv` below `/data`.
2. Attach the matching `Sample_Metadata.csv` as a second Data Asset.
3. Leave all three file-upload controls blank.
4. Enter **Genes to Plot**, for example `Nfil3,Tox,Zbtb16`.
5. Keep **Statistics Source** set to `precomputed_deg` unless an independent
   exploratory test is specifically desired.

The capsule stops rather than guessing if it sees multiple candidate DEG or
metadata files. Use an explicit upload to resolve an intentionally complex
input set.

## Statistics modes

- **`precomputed_deg` (recommended):** labels plots with p-values from the
  original limma/voom (or other compatible) DEG model. It preserves the
  contrast, technical-batch terms, donor blocking, and multiple-testing choice
  used upstream.
- **`within_plot`:** independently calculates simple pairwise tests from the
  values shown in each plot. Use only for exploratory display; it does not
  replicate an upstream model with covariates or paired structure.
- **`none`:** produces plots without statistical annotations.

Choose **nominal** to use `*_pval` columns or **adjusted** to use
`*_adjpval` columns in precomputed mode. Nominal is the default to match the
other OMIX pathway and visualization capsule defaults.

## Inputs and outputs

The expression table may contain normalized CPM, voom-scale expression, or
batch-corrected values. It must contain a feature ID column (default
`GeneName`) and sample columns that match the metadata `Sample` values.

Results contain:

- `gene_boxplots/<gene>.png` — one plot for every requested gene;
- `gene_boxplot_statistics.csv` — pairwise values displayed on plots;
- `gene_boxplot_expression_long.csv` — the actual displayed sample values; and
- `gene_boxplot_run_summary.csv` — run settings and data scope.

## Environment

This adapter is pinned to the immutable OMIX Visualization image tag
`fe132cd082ce9aaf64f925381a92402947de611d`, rather than mutable `latest`.
It includes R 4.4.3 and common plotting dependencies such as `ggplot2` and
`optparse`. No capsule-specific R packages are installed during a run.
