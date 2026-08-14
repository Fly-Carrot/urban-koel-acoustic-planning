# Public script reference

The public interface is deliberately small: 14 ordered drivers call tested shared functions and consume explicit registries. Each card below states what the script does, what it reads, what it writes and what it cannot establish. Historical development scripts are not exposed as alternate entry points.

## `00_preflight`

- **Question:** Is the checkout safe and complete enough to run?
- **Reads:** repository tree, model and predictor registries, reference-product manifest, profile argument.
- **Writes:** `outputs/logs/00_preflight.csv`.
- **Method:** checks the 14-driver contract, documentation cards, disallowed file types, local paths and credential-like strings.
- **Profiles:** identical checks in smoke, verify and full; full also requires `data/full/manifest.csv`.
- **Failure gate:** any missing contract element exits non-zero.
- **Interpretation boundary:** this is a release gate, not a scientific result.

## `01_prepare_survey_histories`

- **Question:** Which station-days are valid surveys, non-detections or missing?
- **Reads:** `survey_reconciliation.csv`; full profile reads scheduled sampled minutes and retained Koel detections.
- **Writes:** `outputs/tables/survey_reconciliation.csv`.
- **Method:** retains effort-confirmed zero detections, keeps missing effort as missing, preserves actual dates and calendar gaps, and reconciles station-day and station-week totals.
- **Key anchors:** 9,912 valid days, 2,682 positive days, 1,500 station-weeks and 1,398,905 sampled-minute opportunities.
- **Failure gate:** mismatched counts or conversion of missing effort to absence.
- **Boundary:** a positive minute is classified acoustic evidence, not abundance or nesting.

## `02_select_detection_backbone`

- **Question:** Which daily conditions explain whether Koel activity is retained by the recording and recognition process?
- **Reads:** model registry; full profile reads daily effort, anthropogenic-event rate and frog-event rate.
- **Writes:** `outputs/tables/model_registry_public.csv`.
- **Method:** registers the frozen logit detection formula `log_effort + log1p_anthropogenic_rate + log1p_frog_rate + site detection intercept`. Richer within/between and SPL formulations remain sensitivity analyses in the article supplement.
- **Failure gate:** response-derived SPL enters the primary survey mask or detection terms drift from the registry.
- **Boundary:** these variables describe observation conditions, not weekly ecological opportunity.

## `03_build_environmental_predictors`

- **Question:** At what ecological extent and map support are predictors defined?
- **Reads:** predictor registry; conditional full profile reads licensed remote-sensing and road products.
- **Writes:** `outputs/tables/predictor_registry_public.csv`.
- **Method:** distinguishes station-centred circular neighbourhoods from fixed HEX reporting cells, validates finite values and records fold-specific scaling requirements.
- **Scale:** 100, 250 and 500 m circles were compared; 250 m was retained as an operational neighbourhood after held-station validation.
- **Failure gate:** test-fold information enters scaling, ecological buffers become HEX geometry, or source licensing is unresolved.
- **Boundary:** 250 m is the retained working scale, not a unique biological truth.

## `04_fit_potential_host_opportunity`

- **Question:** Where and when are three candidate host assemblages acoustically available?
- **Reads:** host-group registry; full profile reads daily assemblage histories and effort.
- **Writes:** `outputs/tables/host_groups.csv` and, conditionally, host posterior surfaces.
- **Method:** each group uses a detection-corrected weekly opportunity model. Complete posterior surfaces are sampled together before downstream Koel fitting.
- **Groups:** four corvid species, three sturnid species and Masked Laughingthrush.
- **Failure gate:** a group is missing, membership changes silently, or site effects are projected to new locations.
- **Boundary:** predicted acoustic co-occurrence is potential-host opportunity; it does not prove local parasitism.

## `05_fit_koel_weekly_opportunity`

- **Question:** How do landscape, annual season and potential-host opportunity organise weekly Koel acoustic activity?
- **Reads:** model registry, model effects and host-posterior surfaces.
- **Writes:** `outputs/tables/model_effects.csv`; full profile also produces posterior draws.
- **Method:** fits the coordinate-free three-host transfer structure at 250 m. In validation, each of three complete host surfaces is used to refit the Koel model and equal numbers of posterior predictions are pooled.
- **Failure gate:** single plug-in host estimates replace posterior surfaces or an occurrence station intercept is assigned to unseen sites.
- **Boundary:** the host block is a joint predictor; its coefficients are not interpreted as independent causal host effects.

## `06_validate_scale_and_transfer`

- **Question:** Does the frozen pipeline travel to an unmonitored station?
- **Reads:** `transfer_validation.csv`; full profile reads five whole-station folds and fold-specific posterior predictions.
- **Writes:** `outputs/tables/transfer_validation.csv`.
- **Method:** withholds complete stations, calculates scaling on training stations, refits host models inside each fold and scores complete daily detection histories. Predictive density is primary; Brier score, calibration and residual Moran's I are supporting diagnostics.
- **Reported comparison:** the three-host coordinate-free model improved held-station ELPD over the matched no-host model; adding coordinates was not clearly supported for that structure.
- **Failure gate:** site leakage, formula refitting after looking at test-fold scores, or a spatial diagnostic overrides poorer prediction.
- **Boundary:** this is conditional spatial validation of a prespecified formula pipeline, not nested model-selection CV.

## `07_fit_joint_calling_density`

- **Question:** Once weekly activity and a positive survey day occur, how densely do positive sampled minutes appear?
- **Reads:** calling-density coefficient summaries, aligned `psi` and `p` draws; full profile reads minute counts by day and hour.
- **Writes:** calling-density summaries and derived exposure products.
- **Method:** positive-day counts follow a zero-truncated beta-binomial component. The host-informed HEQZ branch uses an equal-scale mean of the three standardized potential-host opportunities plus annual season; the hourly extension adds cyclic clock-hour structure.
- **Derived metric:** aligned draws give `E = psi * p * mu_plus`. Window probabilities are simulated from the beta-binomial posterior predictive distribution.
- **Failure gate:** independent-minute multiplication replaces posterior prediction, or unmatched draws are multiplied.
- **Boundary:** `E` is the probability that a scheduled sampled minute is classified Koel-positive under the study design; it is not human annoyance probability.

## `08_predict_citywide_activity`

- **Question:** How do weekly opportunity and acoustic exposure vary across the supported city mapping subset?
- **Reads:** weekly city summary products; full profile reads the transfer-model posterior and HEX-centroid predictors.
- **Writes:** `outputs/tables/weekly_acoustic_opportunity.csv` and `weekly_acoustic_exposure.csv`.
- **Method:** projects the coordinate-free transfer lineage across 52 annual weeks and summarises spatial medians, 10th–90th percentiles and area-weighted means.
- **Failure gate:** monitored-site random effects or support labels enter prediction values.
- **Boundary:** the 5,557-cell centroid-in-city mapping subset differs from the 5,745-cell planning-summary domain and is labelled explicitly.

## `09_classify_prediction_support`

- **Question:** Where can mapped values support interpretation, and where must monitoring come first?
- **Reads:** `prediction_support_classes.csv`; full profile reads land-cover context and seven-variable predictor-space distances.
- **Writes:** `outputs/tables/prediction_support_classes.csv`.
- **Method:** PID identifies ecological interpretation context; AOA compares the mapped predictor combination with the monitored network. Cross-classification gives four support classes.
- **Failure gate:** counts do not sum to 13,714, unsupported cells become low predictions, or categorical permanent water becomes zero exposure.
- **Boundary:** PID and AOA label support without changing predicted values.

## `10_summarise_planning_overlap`

- **Question:** Where do supported acoustic predictions intersect mapped planning-sensitive contexts?
- **Reads:** `planning_overlap.csv`; full profile requires licensed POI and urban-function layers plus posterior products.
- **Writes:** `outputs/tables/planning_overlap.csv`.
- **Method:** POIs inherit the containing HEX; polygonal functions use their actual overlap area. Summaries combine Primary Results and Moderate Extrapolation and propagate 300 posterior draws.
- **Failure gate:** a second 250 m buffer is added, denominators mix support classes, or point and polygon weights are conflated.
- **Boundary:** mapped intersections do not measure realised human presence, annoyance or conflict.

## `11_design_adaptive_monitoring`

- **Question:** Which additional PAM sites would expand environmental representation or validate uncertain predictions?
- **Reads:** anonymised sequence summaries; the full profile requires approved candidate geometries.
- **Writes:** `outputs/tables/adaptive_monitoring_sequences.csv`.
- **Method:** Coverage Expansion greedily maximises prospective AOA coverage in Monitoring Gaps. Prediction Validation ranks spring uncertainty within Primary Results + Moderate Extrapolation. Distance controls reduce redundancy; planning context is a label or tie-breaker.
- **Deployment sizes:** nested scenarios contain 5, 10 and 15 additional stations; the article illustrates 15 stations split 9 + 6.
- **Failure gate:** sequences lose nesting, coordinates leak, or a transparent heuristic is described as a global optimum.
- **Boundary:** proposed centroids still require access, permission, power, security and local-noise checks.

## `12_make_manuscript_outputs`

- **Question:** Can verified numerical products be converted into consistent tables and graphics without changing the science?
- **Reads:** all frozen public reference summaries.
- **Writes:** `outputs/figures/verification_overview.pdf` and machine-readable tables.
- **Method:** uses base-R graphics and values read directly from CSV products.
- **Failure gate:** a model is fitted, a value is typed manually into a figure, or a denominator differs from its source table.
- **Boundary:** the verification figure demonstrates reproducible interfaces and anchors; it is not the submitted figure package.

## `99_validate_release`

- **Question:** Does the complete public release preserve the reported scientific and safety contracts?
- **Reads:** every public driver, registry, reference product and generated output.
- **Writes:** `outputs/diagnostics/release_validation.csv`.
- **Method:** reconciles counts, terms, transfer anchors, support totals, planning denominators and deployment composition, then reruns repository safety checks.
- **Failure gate:** any scientific, terminology, path, privacy, file-type or credential check fails.
- **Boundary:** PASS verifies the curated public release; it does not certify excluded private or third-party inputs.

