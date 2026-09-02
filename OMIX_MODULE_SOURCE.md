# OMIX module source

This repository is the Code Ocean deployment adapter for the canonical OMIX
module:

`NIDAP-Community/OMIX/modules/OMIX-Gene-Boxplots`

The canonical module owns reusable R implementation, a platform-neutral CLI,
tests, and the machine-readable interface schema. This repository owns Code
Ocean-specific input discovery below `/data`, output writing to `/results`, the
App Panel, and the capsule container definition.

Author scientific changes in the OMIX monorepo first, then export the released
module implementation into this repository. If a change starts in a Code Ocean
capsule, test it there, backport the scientific change to the canonical module,
and re-export it here.

Read the [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md#code-ocean-deployment-adapters)
before making changes.
