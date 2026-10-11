# What the public scripts reproduce

`make verify` checks the published aggregate summaries. `make full` is a readable implementation of the selected analysis steps for users with approved model-ready inputs. It does not replay every historical fit.

| Component | Current coverage |
|---|---|
| Sampling | Full-data, sturnid-refit and held-station settings are listed in [mcmc_settings.md](mcmc_settings.md). |
| Model selection | The selected models are provided; the full historical candidate search is recorded in Supplementary Data 4, 8 and 9. |
| Spatial validation | Public code illustrates held-station refitting. The published comparisons also included coordinate-trend alternatives. |
| Predictive scoring | The current public scorer integrates site-week histories separately. Published ELPD used joint whole-station histories and probability-scale pooling over host imputations. These are different scoring procedures. |
| Calling density | Public Stan examples show the hurdle structure. The archived retained hourly model also included annual seasonality and inherited host information. |
| City exposure | Public code accepts reference detection and density draws. Reproducing the published exposure surfaces requires the original matched posterior draws and their spatial and seasonal predictors. |

Use the supplementary workbooks for published estimates. A new full-data run should not be presented as an exact numerical reproduction until these remaining implementation differences are resolved. Raw audio, exact coordinates and restricted spatial inputs are not included.
