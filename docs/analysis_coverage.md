# What can be reproduced now?

`make verify` checks the released aggregate summaries. `make full` runs the public modelling functions with additional model-ready inputs. Those inputs are not included, and the full route has not been tested as a complete numerical reproduction of the paper.

## Available calculations

| Component | Public code |
|---|---|
| Survey preparation | Recording effort is joined to detections; unrecorded surveys remain missing. |
| Host and Koel models | Detection-corrected weekly models; three host posterior surfaces enter separate Koel fits. |
| Spatial validation | Whole stations are withheld; scaling and host refits use training stations only. Complete station histories are scored, with host fits pooled on the probability scale. |
| Calling density | HEQZ daily joint model and D1 cyclic-hour model. Completed draws are combined before exposure is summarised. |
| City prediction | Weekly opportunity, credible intervals and derived sampled-minute exposure. |
| Support and monitoring | Environmental dissimilarity, support classes and candidate ranking. The differences below matter for reproducing the paper. |

## Differences still to resolve

| Part | Current public implementation | Retained study analysis |
|---|---|---|
| Annual timing | `survey_histories.R` assigns ISO weeks; `week_terms()` uses a 52-week cycle. | Supplementary Methods uses a dated annual phase and January-1-based reporting weeks. |
| Support classes | PID PASS + AOA Boundary is assigned to Moderate Extrapolation. | Supplementary Data 13 assigns this combination to Primary Results. |
| Coverage Expansion | The entry point uses the q95 distance threshold; defaults to 1,000 m between selected sites; does not recalculate the complete range/support classification after each selection. | Supplementary Data 16 uses dmax, 4.627 km spacing and updated predictor ranges and dissimilarity. |
| Candidate eligibility | The entry point does not apply the complete route-specific pools or distance-to-existing-station screening. | The study applies both before sequential selection. |
| Planning overlap | The grouped calculation summarises weekly acoustic opportunity. | Supplementary Data 15 also reports dawn expected positive samples and window probabilities. |
| Effort metadata | `data/processed/reference/predictor_registry_public.csv` retains an older effort description. | Fitting code and `config/predictor_registry.csv` use standardised `log1p(recorded sampled minutes / 60)`. |

Historical candidate searches and coordinate-trend comparisons are recorded in the supplementary tables but are not all rerun by `make full`. See [model roles](model_registry.md) and [sampling settings](mcmc_settings.md).

Use the released workbooks for published estimates. Exact reproduction also requires the retained inputs, scaling values, posterior draw schedule and fitted objects. The checks here cover small-data calculations and file consistency; they do not resolve the differences above.
