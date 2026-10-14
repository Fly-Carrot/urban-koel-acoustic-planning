# Selected retained outputs

Coefficient draws and reference summaries for recalculation, not new fits.

- Host coefficient and scaling CSVs: one coefficient vector per host/imputation, station-based weekly and annual scales.
- `weekly_coefficients.csv`: 200 draws per H4 fit (600 pooled) for weekly maps.
- `joint_coefficients.csv`: 100 draws per HEQZ fit (300 pooled) for exposure/planning.
- Hourly coefficients/columns: 100 matched D1 draws.
- Support reference: PID/AOA labels for 13,714 anonymous cells.
- Two sequence CSVs: retained anonymous monitoring ranks.
- Group-draw and weekly-group metrics: reference planning summaries.

H4 and HEQZ coefficients stay separate; treating them as one fit changes the model.

Selected draws suffice for these calculations, not new convergence diagnostics. Complete chains are not distributed. Reported diagnostics are in Supplementary Data 4, 8–12 and 17.
