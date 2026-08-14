# Manuscript supplementary materials

This directory contains the submission-facing supplementary materials for the manuscript *Where wildlife is heard: AI-powered mapping of bird acoustic activity for adaptive monitoring and urban planning*.

The materials are organised as four parallel collections so that readers can open the complete supplement or retrieve an individual table, figure or verification record.

| Collection | Contents | Entry point |
|---|---|---|
| Supplementary Information | Complete Supplementary Methods and captions | [`Supplementary_Information.pdf`](supplementary-information/Supplementary_Information.pdf) |
| Supplementary tables | Seventeen independently downloadable Excel workbooks | [`tables/`](tables/) |
| Supplementary figures | Ten publication-quality PDFs and lightweight PNG previews | [`figures/`](figures/) |
| Manifests | Machine-readable inventory and SHA-256 checksums | [`manifests/`](manifests/) |

## Link to the analytical workflow

The supplementary sections follow the manuscript workflow:

| Supplementary section | Analytical role | Tables | Figures |
|---|---|---|---|
| S1 | Passive acoustic monitoring and AI-assisted identification | S1-S3 | S1 |
| S2 | Daily detection process | S4-S5 | S2 |
| S3 | Environmental and potential-host predictors | S6-S8 | S3 |
| S4 | Weekly Koel acoustic opportunity and spatial transfer | S9-S10 | S4-S5 |
| S5 | Joint calling density and sampled-minute acoustic exposure | S11-S12 | S6 |
| S6 | City prediction, PID and AOA | S13-S14 | S7 |
| S7 | Planning-sensitive places and urban functions | S15 | S8 |
| S8 | Adaptive monitoring design | S16 | S9-S10 |
| S9 | Software, provenance and reproducibility | S17 | - |

## Public-release boundary

The public copies preserve manuscript-facing summaries while protecting recorder security, site privacy and third-party licences. Exact recorder coordinates, exact candidate-HEX identifiers, granular points of interest, raw audio, model weights and third-party source rasters are not redistributed. Public station summaries use anonymised codes `ST01`-`ST31`; monitoring candidates use route-specific ranks `L1`-`L15` and `V1`-`V15`. Figure S1 retains map-scale station context required to understand the validation design, without distributing coordinate records.

The PDF and individual files contain the same scientific results. Stable public filenames are used here even when private production filenames carried dates or workflow labels. See [`manifests/supplementary_artifacts.csv`](manifests/supplementary_artifacts.csv) for the full mapping and provenance description.

## Licensing

Project-owned supplementary text, tables and figures are released under [CC BY 4.0](LICENSE.md). Third-party source data and model assets are excluded or remain under their original terms; see [`../THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).
