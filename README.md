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

## Preserved CCBR implementation

`code/functions/Boxplot_with_Stats.R` is the original CCBR implementation,
preserved as the compatibility reference. Its public
`gene_boxplot_with_stats()` and `gene_boxplot_with_deg_results()` functions
remain intact, including advanced options such as covariate-aware tests,
compact letters, beeswarm points, palette controls, and layout controls.

`code/functions/OMIX_Gene_Boxplots.R` is only the thin workflow wrapper. It
maps tables and `/results` paths into those preserved functions. The only
intentional OMIX default change is that **nominal** p-values are selected by
default for a precomputed DEG result; choose **adjusted** to use the original
DEG-wrapper default.

## Recommended workflow use

For a result from **OMIX DEG Analysis**, attach one result or data asset
containing its two downstream files:

- `DEG_Analysis.csv`, used as both the expression table and the precomputed
  DEG table; and
- `Sample_Metadata.csv`, which supplies the matching sample-level group labels.

The DEG table contains normalized or batch-corrected sample-expression values
and columns like `B-A_pval` and `B-A_adjpval`; the metadata table has `Sample`
and `Group` by default.

When this capsule runs after an upstream DEG capsule in a Code Ocean Pipeline:

1. Connect one DEG Results output (or one Data Asset) containing both files.
   The adapter discovers exactly one supported table with `DEG` in its filename
   and exactly one with `metadata` in its filename below `/data`.
2. Leave all three file-upload controls blank.
3. Enter **Genes to Plot**, for example `Nfil3,Tox,Zbtb16`.
4. Keep **Statistics Source** set to `precomputed_deg` unless an independent
   exploratory test is specifically desired.

The capsule stops rather than guessing if it sees multiple candidate DEG or
metadata files. Use an explicit upload to resolve an intentionally complex
input set. Its default feature ID is `GeneName`, but a common `Gene` column is
detected automatically when that default is absent.

The original default requires at least three samples in each displayed group.

## Statistics modes

- **`precomputed_deg` (recommended):** labels plots with p-values from the
  original limma/voom (or other compatible) DEG model. It preserves the
  contrast, technical-batch terms, donor blocking, and multiple-testing choice
  used upstream. Each comparison is drawn as a horizontal bar above the two
  corresponding groups.
- **`within_plot`:** independently calculates simple pairwise tests from the
  values shown in each plot. Use only for exploratory display; it does not
  replicate an upstream model with covariates or paired structure.
- **`none`:** produces plots without statistical annotations.

Choose **nominal** to use `*_pval` columns or **adjusted** to use
`*_adjpval` columns in precomputed mode. Nominal is the default to match the
other OMIX pathway and visualization capsule defaults.

## Plot appearance

The default visual style is the established CCBR boxplot template: groups are
assigned **Deep Red**, **Vivid Blue**, **Green**, **Purple**, and subsequent
original custom colors in display order; boxes are lightly filled; individual
observations are small filled circles; and a right-side legend is shown.
Comparison bars and italic p-value labels are black. Leave **Group Colors**
blank to retain these defaults, or provide comma-separated original color names
in group order.

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
`optparse`. The next OMIX Visualization image release also includes the legacy
boxplot dependencies `ggbeeswarm`, `broom`, `multcomp`, `multcompView`, and
`RColorBrewer`; use that new immutable image tag once it has been built.
