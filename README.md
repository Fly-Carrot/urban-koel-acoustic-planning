# Urban planning leaves an audible legacy in a megacity’s bird soundscape

Analysis code, supplementary data and model results for a study of Asian Koel vocal activity in Shenzhen, China.

## Materials

| Material | Location |
|---|---|
| Analysis scripts and model functions | [analysis](analysis/), [R](R/) and [Stan models](stan/) |
| Processed study data | [Model inputs](data/model-inputs/) and [data notes](data/README.md) |
| Main model results | [Summaries](results/summaries/) and [posterior draws](results/posterior_draws/) |
| Supplementary Data 1–17 | [Excel workbooks](supplementary-materials/tables/); `Table_S01.xlsx` is Supplementary Data 1 |
| Supplementary methods and figures | [Supplementary Information](supplementary-materials/supplementary-information/Supplementary_Information.pdf) and [figure PDFs](supplementary-materials/figures/) |
| Main figures and Table 1 | [Figures](supplementary-materials/main-figures/) and [Table 1](supplementary-materials/main-tables/) |
| Koel call and song recordings | [Audio examples](supplementary-materials/audio/README.md) |

## Running the code

Install the R packages used to recalculate the study predictions and summaries:

```r
install.packages(c("data.table", "jsonlite", "matrixStats", "reformulas"))
```

Run this command from the repository folder:

```bash
Rscript analysis/reproduce_retained.R
```

Results are saved in `outputs/full/retained_reproduction/`. For model fitting, individual calculations or another dataset, see the [running instructions](data/README.md#running-the-code).

## Citation

Please cite the accompanying manuscript and identify the repository version used. Author and citation details are in [CITATION.cff](CITATION.cff).

Code is [BSD-3-Clause](LICENSE). Project-owned data and supplementary materials are [CC BY 4.0](data/LICENSE.md). OpenStreetMap-derived data retain ODbL terms; see the [source notices](THIRD_PARTY_NOTICES.md).
