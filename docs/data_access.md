# Data access and exclusions

## Included

- reconciled study-level counts;
- model formula and predictor registries;
- posterior coefficient summaries;
- held-station comparison summaries;
- 52-week city summaries without geometry;
- aggregate prediction-support and planning-overlap summaries;
- anonymised adaptive-monitoring sequence diagnostics;
- small synthetic example data for interface checks.

## Excluded

- raw and segmented audio;
- exact current or proposed PAM coordinates and detailed timestamps linked to a location;
- station-level environmental extractions and city geometry;
- granular POI names, identifiers and coordinates;
- third-party remote-sensing rasters and OpenStreetMap extracts;
- BirdNET and other AI model weights;
- MCMC fit objects, compiled Stan binaries and raw chain CSV files;
- private manuscript, cloud and local-workstation paths.

## Full-data contract and current release boundary

The public `full` profile intentionally stops. The repository preserves formulas, registries and exact Stan source, but private-input adapters are not distributed because the required acoustic histories, locations, licensed spatial layers and candidate geometries are restricted. A future approved full release may implement the logical contract below without changing the 14-driver interface.

A user with approved access can create `data/full/manifest.csv` with these logical assets:

| asset_id | required content |
|---|---|
| `survey_histories` | anonymised station-week-day histories, effort and positive-minute counts |
| `host_histories` | matched histories for the three potential-host groups |
| `site_predictors_100_250_500` | circular-neighbourhood predictors at all tested radii |
| `fold_registry` | frozen whole-station fold assignment |
| `city_predictors_250` | approved, licensed HEX-centroid prediction table |
| `poi_and_functions` | licensed planning layers or precomputed aggregate overlaps |
| `source_licences` | machine-readable licence and attribution registry |

An approved implementation must provide a relative path, SHA-256, schema version, licence status and privacy status for every asset. A manifest alone does not enable this pre-publication release and does not waive the user's legal or ethical obligations.
