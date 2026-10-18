# Soft clustering of KORA-FF4

R Markdown analyses of clinical variables, proteomics, and metabolomics for the KORA-FF4 soft clustering project. This public repository contains analysis code and documentation; study data and generated results are held separately in private storage.

## Repository layout

| Folder | Contents |
| --- | --- |
| [`code/clinical/`](code/clinical/) | Clinical archetypal analysis, outliers, stability, MetS, and `Dive_in_MixedEtiology.Rmd` |
| [`code/proteomics/`](code/proteomics/) | Proteomics preprocessing, whole-population analysis, MetS regression, and group analysis |
| [`code/metabolomics/`](code/metabolomics/) | Metabolomics preprocessing, whole-population analysis, MetS regression, and group analysis |
| [`code/multiomics/`](code/multiomics/) | MOFA2 / DIABLO integration |
| [`manuscript/`](manuscript/) | Folder reserved for manuscript material approved for public sharing |
| [`docs/`](docs/) | Private input checklist, preprocessing methods, and data-handling notes |
| [`scripts/`](scripts/) | Preprocessing core, private notebook runner, package checks, and validation helpers |

The clinical notebooks retain their original filenames. Both omics preprocessing workflows are included. The full input checklist and preprocessing details are in [docs/inputs.md](docs/inputs.md) and [docs/preprocessing.md](docs/preprocessing.md).

## Data handling

Raw exports, participant-level information, exclusion lists, fitted models, result tables, figures, reports, and credentials are excluded from this public repository and its published history. The earlier data-bearing repository remains private. See [docs/privacy.md](docs/privacy.md).

Authorized users should obtain the approved study files privately and create a directory **outside this Git checkout**:

```text
private-directory/
  inputs/       # original exports, clinical objects, and existing merged datasets
  config/       # approved sample exclusions
  processed/    # generated proteomics and metabolomics matrices
  work/         # generated analysis outputs, reports, figures, logs, and models
```

Use these local input names:

| File | Purpose |
| --- | --- |
| `inputs/clinical.csv` | Semicolon-separated clinical export; retain its original column order |
| `inputs/Proteomics.csv` | Provider proteomics export, including the `Cohort` column and FF4 samples |
| `inputs/metabolites_p500.csv` | Provider-normalized, imputed, log-transformed and standardized P500 export |
| `config/metabolomics_exclusions.csv` | Approved private exclusions, with one `row_index` column referring to the original export order |

Downstream notebooks also require clinical archetype assignments, fitted models, and merged omics objects. Obtain or generate the specific inputs listed in [the input checklist](docs/inputs.md). A header-only exclusion file excludes no rows; use the study's approved configuration when reproducing its analyses.

## Working with the analyses

### 1. Set up R and private storage

Install R and optionally RStudio, then open `softclustering-KORA.Rproj` or a terminal in the repository root. Checks were run with R 4.6.1; original analysis package versions are not pinned. Preprocessing uses base R; notebook execution requires `knitr` and the packages used by each notebook. MOFA2 also requires its Python backend, and DIABLO requires mixOmics.

In PowerShell, set the private directory and check missing notebook packages:

```powershell
$env:KORA_PRIVATE_DIR = 'D:\approved-project-storage\KORA'
Rscript scripts/check_packages.R
```

Install the packages needed for the notebook you plan to run. The package check does not install software or execute analyses.

### 2. Preprocess proteomics and metabolomics

The notebooks `code/proteomics/Preprocessing_proteomics.Rmd` and `code/metabolomics/Preprocessing_metabolomics.Rmd` call the same core used by these commands:

```powershell
Rscript scripts/preprocess_omics.R proteomics
Rscript scripts/preprocess_omics.R metabolomics
```

Each workflow saves its `Scaled.log.Trans.Proteomics` or `Scaled.log.Trans.Metabolomics` object as `.RData` and `.csv` files under private `processed/`. The inherited filenames do not imply that these scripts perform an additional log or z transformation. See [the preprocessing notes](docs/preprocessing.md) for the exact rules and expected input layouts.

### 3. Follow the analysis order

| Order | Notebook(s) | Purpose |
| --- | --- | --- |
| 1 | `code/clinical/Revise Soft Clustering -Outliers. 08.03.2025.Rmd` | Earlier whole-population clinical analysis |
| 2 | `code/clinical/Revise Soft Clustering -Outliers+MetS. 23.01.2026.Rmd` | Clinical preprocessing, MetS, archetype fitting, and stability |
| 3 | `code/proteomics/whole_population.Rmd`; `code/metabolomics/whole_population.Rmd` | Merge preprocessed omics with clinical variables and archetype assignments |
| 4 | `code/proteomics/mets_regression.Rmd`; `code/metabolomics/mets_regression.Rmd` | MetS-subset regressions |
| 5 | `code/metabolomics/mets_group_analysis.Rmd`, then `code/proteomics/mets_group_analysis.Rmd` | Group comparisons and prediction; proteomics uses the metabolomics grouping output |
| 6 | `code/clinical/Dive_in_MixedEtiology.Rmd` | Mixed etiology comparisons using clinical and omics inputs |
| 7 | `code/multiomics/mofa_diablo_mets.Rmd` | Integration after both omics group workflows |

Run each notebook through the private runner, quoting its path:

```powershell
Rscript scripts/run_analysis.R "code/clinical/Revise Soft Clustering -Outliers+MetS. 23.01.2026.Rmd"
Rscript scripts/run_analysis.R "code/clinical/Dive_in_MixedEtiology.Rmd"
```

The runner resolves standard input reads from private storage and stages execution under private `work/`. Markdown reports, logs, figures, tables, and saved models stay there, including workflow-specific output subfolders. It stops on execution errors.

The notebooks are research working files with exploratory alternatives and expensive fitting steps. Review the required sections, inputs, packages, and participant alignment before running them. The analysis order is a guide; complete study results have not been recomputed for this public release.

### 4. Validate changes before sharing

```powershell
Rscript scripts/check_notebook_syntax.R
Rscript scripts/test_preprocessing.R
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/audit_public.ps1
```

These helpers check R chunk syntax, preprocessing on synthetic data, and the public Git history. Keep all study inputs and generated outputs in private storage.
