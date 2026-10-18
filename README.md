# KORA-FF4 soft clustering

Public analysis code for clinical variables, proteomics, metabolomics, and their integration. Study data, participant identifiers, model objects, results, and reports are kept in separate private storage.

## 1. Get the code and software

Clone this repository and open `softclustering-KORA.Rproj`, or open a terminal in its root folder.

- Install R. Repository checks were run with R 4.6.1; original analysis package versions are not pinned.
- RStudio is optional. Preprocessing uses base R; running notebooks also requires `knitr`.
- Run `Rscript scripts/check_packages.R` to list packages used by the research notebooks that are missing locally. Install the packages required by the notebook you plan to run. MOFA2 additionally needs its Python backend; DIABLO needs mixOmics.

## 2. Supply authorized private inputs

Create a directory **outside this Git checkout** with these subfolders:

```text
private-directory/
  inputs/       # approved original exports and saved analysis objects
  config/       # private sample exclusions
  processed/    # generated omics matrices
  work/         # generated reports, figures, tables, logs, and models
```

Set `KORA_PRIVATE_DIR` in your terminal. For example, in PowerShell:

```powershell
$env:KORA_PRIVATE_DIR = 'D:\approved-project-storage\KORA'
```

Supply these inputs through your approved study-data access route:

| Local filename under `inputs/` | Purpose |
| --- | --- |
| `clinical.csv` | Original clinical export, semicolon-separated; keep its column order |
| `Proteomics.csv` | Original provider proteomics export, including `Cohort` and the FF4 samples |
| `metabolites_p500.csv` | Provider-normalized, imputed, log-transformed and standardized P500 export |
| Clinical model objects and merged datasets | Required for downstream analyses; see [the input checklist](docs/inputs.md) |

For metabolomics, obtain the reviewed `config/metabolomics_exclusions.csv` privately. It has one column, `row_index`, referring to the original export order. A header-only file means no exclusions; do not use that as a substitute for the study's approved exclusions. No sample row numbers are distributed in this repository.

## 3. Run both preprocessing workflows

From the repository root:

```powershell
Rscript scripts/preprocess_omics.R proteomics
Rscript scripts/preprocess_omics.R metabolomics
```

The corresponding notebooks are:

- `code/proteomics/Preprocessing_proteomics.Rmd`
- `code/metabolomics/Preprocessing_metabolomics.Rmd`

Both are included and call the same executable preprocessing core. Each writes `Scaled.log.Trans.Proteomics` or `Scaled.log.Trans.Metabolomics` as `.RData` and `.csv` files under the private `processed/` folder. The filenames are inherited; the scripts do **not** apply an additional log or z transformation. See [the preprocessing notes](docs/preprocessing.md) for exact rules and input layout checks.

## 4. Run analyses in this order

The clinical filenames are restored exactly:

1. `code/clinical/Revise Soft Clustering -Outliers. 08.03.2025.Rmd` — earlier whole-population clinical analysis.
2. `code/clinical/Revise Soft Clustering -Outliers+MetS. 23.01.2026.Rmd` — clinical MetS and archetype analysis.
3. `code/proteomics/whole_population.Rmd` and `code/metabolomics/whole_population.Rmd` — merge preprocessed omics with clinical variables and archetype assignments.
4. `code/proteomics/mets_regression.Rmd` and `code/metabolomics/mets_regression.Rmd` — MetS-subset regressions.
5. `code/metabolomics/mets_group_analysis.Rmd`, then `code/proteomics/mets_group_analysis.Rmd` — group comparisons and prediction. Proteomics consumes the metabolomics grouping output.
6. `code/multiomics/mixed_etiology.Rmd` — mixed etiology comparisons; `code/multiomics/mofa_diablo_mets.Rmd` — integration after both group workflows.

Run each notebook with the private runner, quoting its path:

```powershell
Rscript scripts/run_analysis.R "code/clinical/Revise Soft Clustering -Outliers+MetS. 23.01.2026.Rmd"
Rscript scripts/run_analysis.R "code/metabolomics/mets_group_analysis.Rmd"
```

The runner stages the notebook under private `work/`, resolves standard input reads from private `inputs/` and `processed/`, and keeps logs, Markdown reports, plots, tables, and models in private storage. It stops at execution errors. Research notebooks still contain exploratory branches and expensive fitting steps: review the needed sections, inputs, and packages before running. This is an analysis order, not a claim that the entire study has been rerun successfully.

## 5. Check changes before sharing

```powershell
Rscript scripts/check_notebook_syntax.R
Rscript scripts/test_preprocessing.R
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/audit_public.ps1
```

The privacy audit checks tracked paths and all local Git objects. Keep data and outputs out of commits even when collaborating privately. The public repository starts with a new code-only history; the earlier data-bearing repository remains private. See [privacy and history](docs/privacy.md).
