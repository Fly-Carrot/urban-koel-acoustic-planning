# What the public scripts reproduce

`make verify` checks the published aggregate summaries. `make full` is a readable implementation of the selected analysis steps for users with approved model-ready inputs. It does not replay every historical fit.

| Component | Current coverage |
|---|---|
| Sampling | Full-data, sturnid-refit and held-station settings are listed in [mcmc_settings.md](mcmc_settings.md). |
| Model selection | The selected models are provided; the full historical candidate search is recorded in Supplementary Data 4, 8 and 9. |
| Spatial validation | Public code illustrates held-station refitting. The published comparisons also included coordinate-trend alternatives. |
| Predictive scoring | Complete station histories share an unseen-station detection effect. ELPD integrates the joint history, then pools the three host imputations on the probability scale. Site-week predictions are retained for calibration, not used as the ELPD scoring unit. |
| Calling density | The three HEQZ joint fits retain host and annual effects. The D1 hourly fit retains annual terms, two hour harmonics and positive-day conditioning. City density inherits host and annual effects from HEQZ and hour effects from D1. |
| City exposure | Occurrence, reference detection and HEQZ density coefficients are taken from the same joint posterior row. The D1 hour profile and dispersion are paired by draw. Exposure is calculated before posterior summaries, with equal contributions from the three imputations. |

Use the supplementary workbooks for published estimates. The public route documents the retained calculation, while omitting historical candidate runs and coordinate-trend comparisons. Synthetic tests check scoring and exposure calculations; the private-data pipeline has not been rerun as an end-to-end numerical reproduction. Exact published values also require the retained inputs, scaling records, draw schedule and posteriors. Raw audio, exact coordinates and restricted spatial inputs are not included.
