# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX Gene Boxplots](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Gene-Boxplots)
- **Canonical path:** `modules/OMIX-Gene-Boxplots/`
- **Canonical module version:** `1.0.0`
- **Canonical interface version:** `1`
- **Canonical release tag:** Pending — baseline tag not yet established.
- **Canonical source reference:** [`7da6208330c72c8e1f123ba6e9de9f5c1f745dbb`](https://github.com/NIDAP-Community/OMIX/commit/7da6208330c72c8e1f123ba6e9de9f5c1f745dbb)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-Gene-Boxplots/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

| Canonical file | Adapter copy | Purpose |
| --- | --- | --- |
| `R/Boxplot_with_Stats.R` | `code/functions/Boxplot_with_Stats.R` | Preserved CCBR boxplot implementation. |
| `R/OMIX_Gene_Boxplots.R` | `code/functions/OMIX_Gene_Boxplots.R` | Workflow-facing wrapper around the preserved implementation. |

The listed exports were verified byte-for-byte against the canonical source
reference above.

Canonical `1.0.0` changes duplicate normalized-expression handling to a
sample-wise mean by default. The adapter exposes the canonical
`duplicate_aggregation` choices `mean`, `sum`, and `keep`; `sum` is retained
for legacy reproduction and `keep` leaves duplicate rows uncombined.

## Adapter release record

| Field | Recorded value |
| --- | --- |
| Adapter version | Pending — next release will align with canonical module `1.0.0` after platform validation. |
| Adapter release tag | Pending. |
| Platform release | Pending validation record. |
| Runtime identity | Not yet recorded as an immutable image digest or lockfile reference. |

See the [OMIX versioning and release policy](https://github.com/NIDAP-Community/OMIX/blob/main/docs/versioning-and-releases.md). The source commit, adapter tag, platform release, and runtime identity are separate records.

## Adapter-only support code

`code/functions/workflow_input.R` resolves platform workflow inputs. It is
adapter support code, not an exported scientific function.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior, schemas,
tests, and scientific documentation. This adapter owns deployment UI, input
discovery, result paths, runtime setup, and the platform entry point.

Make reusable changes in the canonical module, update its tests and interface,
record the next canonical version and immutable source reference here, and then re-export the listed
files without unreviewed behavioral changes. Validate the adapter with
representative deployment inputs before release.
