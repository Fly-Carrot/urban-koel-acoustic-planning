# Reproducing the public release

## Verification in a clean clone

```bash
make setup
make verify
make test
```

`verify` executes the 14 public drivers in order. The drivers validate and copy frozen reference summaries into `outputs/`, generate `verification_overview.pdf`, and then enforce the numerical, terminology, privacy and release contracts. A failed check stops with a non-zero exit code.

The public verification path uses base R so that the reported summary products remain easy to inspect. The analysis was developed with additional Bayesian and spatial libraries listed in `docs/system_requirements.md`; these are needed only for the conditional full profile.

## Smoke profile

```bash
make smoke
```

The smoke profile checks interfaces and release invariants quickly. It is a software test and does not create new ecological evidence.

## Full-profile boundary

```bash
make full
```

The command stops with an explicit boundary message in this pre-publication release. The repository preserves the complete public interface, model registry and final Stan source, while the private-input adapters and restricted source assets remain excluded. An approved future implementation would require effort-confirmed Koel and potential-host histories, licensed environmental covariates, anonymised fold membership, approved city predictor assets and the posterior-draw schedule. Exact logical assets and access boundaries are documented in `docs/data_access.md`.

The current article-facing products propagate three independently sampled, complete potential-host opportunity surfaces through each validation fold. This M=3 design checks that the transfer conclusion is not driven by one host-posterior draw; it is a computationally bounded uncertainty propagation, not an adaptive large-M stabilization claim.

## Determinism and tolerances

- Frozen CSV products use invariant counts and numerical tolerance tests.
- PDF files are regenerated but are not compared byte-for-byte because graphics devices can differ across systems.
- Any proposed change to a reported value must update the source registry, expected tests, changelog and release version together.

## Clean-clone check

Before a release, clone the pushed repository into a new directory and run:

```bash
make setup
make contract
make verify
make test
git status --short
```

The final command should show only ignored files below `outputs/`.
