# File inventory and checksums

[supplementary_artifacts.csv](supplementary_artifacts.csv) lists the 48 PDFs, workbooks and previews with their full titles, source version, redactions, licences and hashes.

[checksums.sha256](checksums.sha256) covers every file in this supplementary directory except itself. To check the files, run from the repository root:

```bash
cd supplementary-materials
shasum -a 256 -c manifests/checksums.sha256
```
