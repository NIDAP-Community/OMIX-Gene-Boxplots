# OMIX Gene Boxplots adapter instructions

This repository is a Code Ocean deployment adapter. Read
[AGENTS.md](../AGENTS.md) and
[OMIX_MODULE_SOURCE.md](../OMIX_MODULE_SOURCE.md) before modifying it.

- Keep portable scientific behavior in the canonical OMIX module first.
- Keep Code Ocean-specific `/data` discovery, `/results` output, App Panel, and
  environment files in this repository.
- Validate that user uploads override workflow discovery and that ambiguous
  files stop with a clear error rather than selecting one silently.
- Do not add research data or generated results to Git.
