# Canonical OMIX Module Source

## Canonical module

- **Module:** [OMIX Gene Boxplots](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-Gene-Boxplots)
- **Canonical path:** `modules/OMIX-Gene-Boxplots/`
- **Released source reference:** [`2987296a45a2a11e6c4b3454c813a63ae6db6ac0`](https://github.com/NIDAP-Community/OMIX/commit/2987296a45a2a11e6c4b3454c813a63ae6db6ac0)
- **Interface schema:** [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-Gene-Boxplots/schemas/interface.yml)
- **Module contract:** [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)

## Exported scientific files

| Canonical file | Adapter copy | Purpose |
| --- | --- | --- |
| `R/Boxplot_with_Stats.R` | `code/functions/Boxplot_with_Stats.R` | Preserved CCBR boxplot implementation. |
| `R/OMIX_Gene_Boxplots.R` | `code/functions/OMIX_Gene_Boxplots.R` | Workflow-facing wrapper around the preserved implementation. |

The listed exports were verified byte-for-byte against the released source
reference above.

## Adapter-only support code

`code/functions/workflow_input.R` resolves platform workflow inputs. It is
adapter support code, not an exported scientific function.

## Ownership and synchronization

The canonical module owns scientific functions, portable CLI behavior, schemas,
tests, and scientific documentation. This adapter owns deployment UI, input
discovery, result paths, runtime setup, and the platform entry point.

Make reusable changes in the canonical module, update its tests and interface,
record the next released source reference here, and then re-export the listed
files without unreviewed behavioral changes. Validate the adapter with
representative deployment inputs before release.
