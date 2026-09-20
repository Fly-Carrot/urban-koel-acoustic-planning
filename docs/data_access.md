# Data access

## Included

- manuscript and Supplementary Information files;
- aggregate model, validation, prediction and monitoring summaries;
- synthetic example data;
- R and Stan analysis code.

## Not redistributed

- raw or segmented audio;
- exact recorder and candidate-site coordinates;
- event-level detections and detailed timestamps linked to locations;
- granular POI records;
- licensed remote-sensing, road and administrative spatial data;
- AI model weights and raw MCMC chains.

These exclusions reflect data volume, site security, privacy and third-party licences.

## Model-ready inputs

The full analysis reads logical assets from `data/full/manifest.csv`. Copy [`../config/full_data_manifest_example.csv`](../config/full_data_manifest_example.csv), replace each example path with an approved local file, and keep the data outside Git.

Station and candidate identifiers may be anonymised. Files used for spatial prediction must retain a common cell identifier, while exact geometry can remain in the user's protected workspace.
