# Provenance and release lineage

This repository is a curated public interface assembled from the corrected-effort analysis lineage frozen in July–August 2026. It is not a mirror of the development workspace.

The active internal lineage proceeded through:

1. corrected survey effort and detection-backbone auditing;
2. potential-host and Koel model development;
3. fivefold whole-station transfer and 100/250/500 m sensitivity;
4. host-mechanism and transfer reconciliation;
5. daily and hourly joint calling-density models;
6. support-aware city prediction, planning overlap and adaptive monitoring;
7. manuscript product synchronization and audit.

Machine-readable public provenance is in `config/provenance_registry.csv` and `data/manifests/reference_products.csv`. Legacy internal IDs occur only in that registry so that reported values remain traceable; user-facing analysis and output names use ecological terms.

Important release boundary: article-facing host uncertainty uses three independently sampled complete host-posterior surfaces. This establishes draw-wise robustness for the reported transfer comparison but does not claim adaptive M10/M20 stabilization. A future full release can upgrade this component without changing the public driver interface.

