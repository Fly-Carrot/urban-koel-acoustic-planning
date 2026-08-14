# Supplementary-material manifests

- [`supplementary_artifacts.csv`](supplementary_artifacts.csv) records each public PDF, workbook and PNG preview, its manuscript section, stable filename, source lineage, privacy treatment, licence, file size and SHA-256 digest.
- [`checksums.sha256`](checksums.sha256) covers every file in `supplementary-materials/` except the checksum file itself.

Verify the complete collection from the repository root with:

```bash
cd supplementary-materials
shasum -a 256 -c manifests/checksums.sha256
```
