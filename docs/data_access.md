# Data access

## Available here

- Supplementary Methods, tables and figures from the 11 October 2026 export;
- aggregate model, validation, prediction and monitoring summaries;
- synthetic example data for checking calculations;
- R analysis code and four Stan model definitions.

The main manuscript is not included. Public summaries describe the reported results, but are not the station-level inputs required to refit the models.

## Not included

Raw recordings, event-level detections, model-ready station-level tables, exact recorder and candidate coordinates, detailed POI records, source rasters, trained AI weights and raw MCMC chains are not included in this release. Coordinate redactions are described in the [supplementary index](../supplementary-materials/README.md). Dataset sources and terms are listed in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) and Supplementary Data 7 and 15.

This repository does not currently provide a download or request procedure for the missing model-ready inputs.

## Inputs for model fitting

[config/full_data_manifest_example.csv](../config/full_data_manifest_example.csv) lists the 16 input entries used by `make full`. To use compatible inputs of your own, copy it to `data/full/manifest.csv` and replace the example paths. Keep private data outside Git.

The [data dictionary](data_dictionary.md) describes the fields. Station identifiers can be anonymised, but station/day/week keys and city cell identifiers must match across files. See [code coverage](analysis_coverage.md) for differences to address before reproducing the published analysis.
