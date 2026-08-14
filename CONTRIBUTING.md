# Contributing

Thank you for helping make this workflow easier to inspect and reuse.

1. Open an issue describing the scientific or software problem.
2. Create a focused branch and avoid committing raw audio, exact monitoring coordinates, credentials, local absolute paths, large generated files or third-party data.
3. Preserve the distinctions among weekly opportunity (`psi`), detectability (`p`), positive-day minute probability (`mu_plus`) and sampled-minute exposure (`E`).
4. Add or update tests and the corresponding script card.
5. Run `make smoke`, `make verify` and `make test` before opening a pull request.

Changes to model formulae, prediction-support rules, thresholds, spatial folds or reported numerical anchors require an explicit scientific decision record and a new release version.

