# Verification — 15 October 2026

| Check | Result |
|---|---|
| Input export | 2,243 numeric round-trip checks passed; 296 released input/output files checksummed and scanned |
| Survey coverage | 31 stations; 9,912 observed days; 4,844 missing slots; 2,682 Koel-positive days |
| Weekly city prediction | All 713,128 rows matched the retained product; maximum absolute difference 1.09 × 10⁻¹² |
| Planning summaries | All 2,700 group-draw summaries matched; maximum absolute difference 4.14 × 10⁻¹³ |
| Support classes | 2,712 Primary Results; 3,033 Moderate Extrapolation; 7,066 Monitoring Gaps; 903 outside domain |
| Monitoring | Both 15-candidate sequences matched; nine expansion sites represented 6,884 current gap cells |
| Materials | 48 current SA assets; 5,853 workbook cells checked, with styles and formulas preserved |
| Code checks | `make verify`, `make test`, `make smoke` and file/privacy/link checks passed |

Differences at approximately 10⁻¹² reflect numerical precision in exported values. No source manuscript or retained result was changed.

The occupancy fitting interface was also tested on the actual H4 input with a deliberately short run. That run tested the interface only, not parameter convergence. Full historical MCMC searches, complete raw chains and geometry-dependent residual analyses were not rerun or released. See [coverage](analysis_coverage.md).
