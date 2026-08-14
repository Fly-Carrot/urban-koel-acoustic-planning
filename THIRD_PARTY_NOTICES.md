# Third-party sources and notices

This repository does not redistribute the source rasters, raw OpenStreetMap records, AI model weights or raw acoustic recordings used in the full study. Users running the conditional full profile must obtain each asset from its provider and comply with its terms.

| Source | Study use | Redistribution in this repository | Licence and official source |
|---|---|---|---|
| Dynamic World V1 | probabilistic land-cover summaries | No source raster | CC BY 4.0; [Earth Engine catalogue](https://developers.google.com/earth-engine/datasets/catalog/GOOGLE_DYNAMICWORLD_V1) |
| JRC Global Surface Water v1.4 | nearest-water context | No source raster | Copernicus free and open access terms; [Earth Engine catalogue](https://developers.google.com/earth-engine/datasets/catalog/JRC_GSW1_4_Metadata) |
| NASA SRTMGL1 v3 | elevation | No source raster | NASA Earth Science Data and Information Policy; [Earthdata record](https://www.earthdata.nasa.gov/data/catalog/lpcloud-srtmgl1-003) |
| ESA WorldCover 2021 v200 | categorical permanent-water exclusion | No source raster | CC BY 4.0; [ESA WorldCover data access](https://esa-worldcover.org/en/data-access) |
| OpenStreetMap | POI and urban-function source records | No granular records or derived database | ODbL 1.0; © OpenStreetMap contributors; [copyright and licence](https://www.openstreetmap.org/copyright) |
| AudioMoth | acoustic acquisition hardware | Not applicable | Open hardware documentation; [Open Acoustic Devices](https://www.openacousticdevices.info/audiomoth) |
| BirdNET v2.4 | locally adapted species classification | No code or model weights | Analyzer code and model assets have different terms; model weights are CC BY-NC-SA 4.0; [BirdNET-Analyzer](https://github.com/birdnet-team/BirdNET-Analyzer) |

Derived project-owned aggregate summaries under `data/processed/reference/` contain no source pixels, granular OSM records, exact coordinates or model weights. Their scoped licence is documented in `data/LICENSE.md`; the root BSD licence applies only to software and documentation owned by the contributors.
