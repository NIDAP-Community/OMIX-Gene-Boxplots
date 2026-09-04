# Deployment Adapter Agent Instructions

This repository is a deployment adapter for the canonical OMIX module recorded
in [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md). Read that file, this
repository's README, and the canonical [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md)
before editing.

## Ownership

- The canonical module owns scientific functions, scientific defaults,
  portable CLI behavior, schemas, and tests.
- This repository owns the deployment UI, attached-input discovery, result
  paths, runtime configuration, and platform entry point.
- Preserve the original CCBR plot aesthetics and behavior. Do not permanently
  change exported scientific functions here; backport scientific or reusable
  interface changes to the canonical module first.

## Working rules

1. Inspect Git status, the app-panel definition, `OMIX_MODULE_SOURCE.md`, and
   the canonical schema before editing.
2. Keep user uploads higher priority than workflow discovery. Discover attached
   data only when exactly one candidate matches; otherwise report candidates
   and require explicit selection.
3. Preserve stable output names, original plot appearance, and the paired DEG
   table plus sample metadata handoff.
4. Use the named pinned runtime. Do not rebuild unrelated shared environments
   or use an unpinned `latest` image.
5. Do not commit input data, generated results, credentials, package caches,
   or package-inventory archives.
6. Validate an adapter change with a representative deployment run and report
   separately what was tested locally, in the deployment environment, and not
   tested.

## Release discipline

- Keep the README and `OMIX_MODULE_SOURCE.md` current with the canonical
  module link, canonical module/interface versions, and immutable source
  reference.
- Before release, confirm Git is clean, inputs are unambiguous, the app panel
  matches the intended interface, the environment is pinned, and the workflow
  handoff works when applicable.
- Create an adapter release tag only after platform validation. Record the
  adapter tag, platform release identifier, and runtime tag plus digest in
  `OMIX_MODULE_SOURCE.md`; mark unavailable values as pending rather than
  guessing.
