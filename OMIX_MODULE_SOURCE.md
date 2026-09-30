# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX Gene Boxplots](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Gene-Boxplots)
- **Canonical path:** `modules/OMIX-Gene-Boxplots/`
- **Canonical module version:** `1.0.0`
- **Canonical interface version:** `1`
- **Canonical release tag:** Pending — baseline tag not yet established.
- **Canonical source reference:** [`eee4433cd74d0ce9bd1daba1571ca6312cba7ea2`](https://github.com/NIDAP-Community/OMIX/commit/eee4433cd74d0ce9bd1daba1571ca6312cba7ea2)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-Gene-Boxplots/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

| Canonical file | Adapter copy | SHA-256 | Purpose |
| --- | --- | --- | --- |
| `R/Boxplot_with_Stats.R` | `code/functions/Boxplot_with_Stats.R` | `dd4ce18058849c8560b8f137b2d8ab9b1712c88fbbd256be3ecd505469620715` | Preserved CCBR boxplot implementation. |
| `R/OMIX_Gene_Boxplots.R` | `code/functions/OMIX_Gene_Boxplots.R` | `9a5b8405b11347e63a7e2433356a55ec4c03f46fcbe09b1ef3bd5a3f142e6801` | Workflow-facing wrapper around the preserved implementation. |

The listed exports were verified byte-for-byte against the canonical source
reference above.

The completed canonical `schemas/interface.yml` used to build the App Panel
has SHA-256
`57f2aee00ad5cdbccbfdb6c78ef6c89d392d0f60506d2d5eacca61c9d3f28033`.
`code/functions/` contains only the complete two-file canonical `R/` export;
Code Ocean input discovery is kept separately in `code/adapter_io.R`.

Canonical `1.0.0` changes duplicate normalized-expression handling to a
sample-wise mean by default. The adapter exposes the canonical
`duplicate_aggregation` choices `mean`, `sum`, and `keep`; `sum` is retained
for legacy reproduction and `keep` leaves duplicate rows uncombined.

## Platform translations

- Canonical inputs `expression_table`, `metadata_table`, and `deg_table` use
  those exact named-parameter bindings. An uploaded file takes priority; when
  a selector is blank, the adapter discovers one unambiguous matching file
  recursively below `/data` and stops with candidate paths on ambiguity.
- Canonical `gene_column` supplies both the expression-table gene identifier
  and the internal `deg_gene_column` function argument. The internal binding
  is not a separate public App Panel control.
- Canonical `output_dir` is platform-owned and intentionally hidden. The
  capsule writes to `/results`; a local adapter run falls back to the
  repository `results/` directory only when `/results` does not exist.
- All other public and advanced controls use their canonical names, types,
  choices, order, and scientific defaults. In particular, exported images
  default to 6 inches wide, 5 inches high, and 300 DPI.

<!-- omix-adapter-contract: {"aliases": {}, "hidden_inputs": [{"canonical": "output_dir", "binding": "/results (repository results/ fallback outside Code Ocean)", "reason": "Code Ocean owns the capsule result mount"}]} -->

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | Pending — next release will align with canonical module `1.0.0` after platform validation. |
| Adapter release tag | Pending. |
| Platform release | Pending validation record. |
| Runtime tag | `codeocean/omix-r-visualization:r4.4.3-v2` (from `.codeocean/environment.json`). |
| Runtime digest | Pending — no immutable digest has been validated or recorded. |
| Named-parameter platform run | Pending — GitHub/local checks are not Code Ocean validation. |
| Syncweaver lock | Pending — no generated `.syncweaver-lock.json` is recorded. |

See the [OMIX versioning and release policy](https://github.com/NIDAP-Community/OMIX/blob/main/docs/versioning-and-releases.md). The source commit, adapter tag, platform release, and runtime identity are separate records.

## Adapter-only support code

`code/adapter_io.R` resolves platform workflow inputs and reads deployment
files. It is adapter support code, not an exported scientific function.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior, schemas,
tests, and scientific documentation. This adapter owns deployment UI, input
discovery, result paths, runtime setup, and the platform entry point.

Make reusable changes in the canonical module, update its tests and interface,
record the next canonical version and immutable source reference here, and then re-export the listed
files without unreviewed behavioral changes. Validate the adapter with
representative deployment inputs before release.
