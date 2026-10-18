# Preprocessing workflows

Both original preprocessing notebooks were found in the project's `Code/Proteomics code` and `Code/Metabolomics code` folders. They were absent from the first repository upload. Their filenames are now included, with runnable preprocessing cores in `scripts/preprocess_omics.R`.

## Proteomics

`Preprocessing_proteomics.Rmd` originally reads the multi-cohort `Proteomics.csv`, selects `Cohort == "FF4"`, and treats columns 181–1022 as protein measurements with the identifier in column 3. The extracted core validates this layout and protein-name prefixes before proceeding. For each feature it replaces values at or beyond the lower/upper 1.5 IQR fences with the feature median, then selects the identifier plus proteins and removes incomplete rows. Sample identifiers must be nonmissing and unique.

Outputs are the object `Scaled.log.Trans.Proteomics` saved as `.RData` and a CSV in private `processed/`. The core does not apply a log or z transform. Upstream provider processing must be established from the approved input's provenance; the inherited output name does not prove how raw measurements were transformed.

## Metabolomics

`Preprocessing_metabolomics.Rmd` starts from the provider's P500 export, which is already normalized, imputed, log-transformed and standardized. It expects the original layout: column 3 is the identifier and columns 46–433 are metabolite measurements. The core selects these columns, applies the authorized exclusions from the external private `row_index` configuration, checks completeness and unique identifiers, and saves `Scaled.log.Trans.Metabolomics` as `.RData` and CSV.

The original notebook creates `Data.Metabolomics` before its diagnostic IQR replacement loop. That loop updates `Metabolomics.Data.P500`, while the saved `Scaled.log.Trans.Metabolomics` comes from the earlier `Data.Metabolomics`. The extracted core preserves the exported matrix's behavior; it does not silently add IQR replacement to it. Diagnostic PCA/boxplot branches, placeholder rendering, and unrelated analysis drafts are omitted from the executable preprocessing core.

The original row exclusions have been moved to local private configuration. They are tied to a particular input order; obtain the approved configuration privately and verify the export version. A header-only exclusions file deliberately excludes no rows and does not reproduce a study run with exclusions.

## Validation

`scripts/test_preprocessing.R` uses generated synthetic measurements to check cohort selection, outlier replacement, missing-row handling, identifier preservation, private exclusions, invalid layouts, and serialization. It does not use study data. Syntax checks cover all R chunks. The complete statistical analyses and full original preprocessing runs have not been rerun on study inputs.
