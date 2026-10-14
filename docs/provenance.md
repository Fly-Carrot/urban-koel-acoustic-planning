# Where the files come from

The [Methods-to-code map](code_map.md) links each analysis step to its inputs, calculations and outputs.

Public CSV files in `data/processed/reference/` contain reported aggregate summaries. Their sources are recorded in [config/provenance_registry.csv](../config/provenance_registry.csv), and their hashes in [data/manifests/](../data/manifests/).

The [supplementary inventory](../supplementary-materials/manifests/supplementary_artifacts.csv) records the source version and redactions for each public PDF, workbook and preview. These files were last updated on 15 October 2026.

New model-fitting results go to `outputs/full/`. They are separate from the released reference summaries. See [code coverage](analysis_coverage.md) before comparing them with published estimates.
