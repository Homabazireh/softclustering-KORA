# Public code and private study storage

This repository contains source code and documentation only. No raw exports, participant-level datasets, saved fitted models, result tables, diagnostic plots, rendered notebooks, credentials, data fingerprints, or participant exclusion lists belong here.

The original data-bearing repository must remain private. Its commits cannot be made safe by merely deleting data in a later commit. The public code is published from an independently initialized Git repository with a new root commit; no private branches, tags, prior commits, or binary objects are imported. The private repository is retained separately for authorized collaborators.

`KORA_PRIVATE_DIR` points outside the checkout. Inputs, exclusion configuration, processed matrices, and every analysis report/output stay under that private directory. Local usernames and original source-file paths have been removed from the public notebooks. Recorded numeric result comments and an output-only clinical chunk have been removed. The clinical source filenames are preserved exactly; their published contents have these privacy edits.

`.gitignore` excludes study-data and output directories, common dataset/model/report formats, local environment files, and credential files. `scripts/audit_public.ps1` independently checks every committed tree and all local Git objects against an explicit source-file allowlist and scans blob contents for recognizable secrets, local source paths, and source-export identifiers. An allowed file extension is not proof of safe content: review source changes for embedded participant information before publication.

Do not add real sample identifiers, row-level values, exclusion indices, screenshots, reports, or private file contents to public issues or pull requests. Logs may contain participant information and always remain private. The privacy check and review cover the prepared public snapshot; they do not grant permission to share future outputs.
