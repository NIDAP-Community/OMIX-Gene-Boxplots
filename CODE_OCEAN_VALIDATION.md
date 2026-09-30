# Code Ocean validation plan

This plan records the platform checks required after the pull request is
merged. Local and GitHub checks do not satisfy these gates.

## Candidate identity

Record all of the following before the run:

- merged adapter commit;
- Code Ocean capsule/release identifier;
- canonical OMIX commit from `OMIX_MODULE_SOURCE.md`;
- `codeocean/omix-r-visualization:r4.4.3-v2` plus its resolved immutable
  digest; and
- attached input asset or upstream-result identity.

## Required named-parameter runs

1. Attach one OMIX DEG result containing `DEG_Analysis.csv` and
   `Sample_Metadata.csv`. Leave all file selectors blank, select at least one
   gene, and confirm unambiguous recursive discovery plus outputs in
   `/results`.
2. Upload the expression and metadata files explicitly and confirm uploads
   take priority over attached candidates. Repeat with a separate DEG table.
3. Confirm that two matching attached DEG files stop with candidate paths
   rather than choosing one silently.
4. Run `duplicate_aggregation` as `mean`, `sum`, and `keep`; confirm the long
   expression output and run summary match the local fixture expectations,
   including partial and all-missing duplicate values.
5. With `precomputed_deg`, compare nominal and adjusted annotations. Confirm
   the established group colors, lightly filled boxes, individual points,
   right-side legend, black italic labels, and horizontal comparison bars.
6. Confirm default PNG dimensions are 6 by 5 inches at 300 DPI and that all
   four stable output families are present.

## Evidence to record

Add the exact run or release URL, timestamp, input identity, output manifest,
representative plot, runtime tag and digest, and pass/fail notes to
`OMIX_MODULE_SOURCE.md`. Only after those facts are recorded may the adapter
be tagged or described as platform validated.
