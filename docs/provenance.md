# Provenance

The ordered scripts follow the analysis reported in the manuscript. Public summary files in `data/processed/reference/` provide a lightweight check of reported values. The `full` route reads approved model-ready inputs and writes new results below `outputs/full/`.

The link from each method to its script, input and output is listed in [`code_map.md`](code_map.md). Public summary provenance is recorded in [`../config/provenance_registry.csv`](../config/provenance_registry.csv), and checksums are recorded in `data/manifests/` and `supplementary-materials/manifests/`.

Three complete host posterior surfaces are propagated through the primary Koel model. This is the uncertainty treatment reported in the article; it should not be described as a large multiple-imputation analysis.
