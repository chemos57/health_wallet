# Summary of Changes

## Laboratory Results Import

- Added upload/status pages for simplified HL7 laboratory result files.
- Added `LaboratoryImport` Mongoid records to track uploaded files, status, error messages, processed timestamps, and import counters.
- Added `LaboratoryImportJob` to process uploaded files in the background.
- Added routes for `laboratory_imports#index`, `new`, `create`, and `show`.
- Added bottom navigation links so users can move between Patients and Imports from every page.

## Service Layer

- Added `dry-monads` and `sorbet-runtime`.
- Kept Sorbet and dry-monads scoped to the new service layer only.
- Added typed service/value objects under `app/services/laboratory_results/`.
- Added parser support for one or more assessments per file.
- Added validation for:
  - empty files
  - malformed lines
  - observation rows before assessment headers
  - invalid dates
  - invalid sex at birth values
  - unsupported LOINC codes
  - non-numeric observation results
  - missing units
- Added importer support for:
  - finding or creating patients by name, date of birth, and sex at birth
  - finding or creating assessments by patient/reference
  - creating or updating embedded observations by code

## User Interface

- Added laboratory import index, upload, and status pages.
- Added upload entry point from the home page.
- Added status badges for pending, processing, completed, and failed imports.
- Added global footer navigation buttons for Patients and Imports.

## Example Files

- Added sample files from `FHM_CODING_TASK.md`:
  - `John_Doe_HL7.txt`
  - `Jane_Smith_HL7.txt`
  - `Multiple_Patients_HL7.txt`

## Tests

- Added parser tests for valid files, multiple assessments, unsupported codes, invalid results, and misplaced observations.
- Added importer tests for creating records and updating existing observations.
- Added job tests for completed imports, failed imports, and top-level service constant lookup.
- Added controller tests for upload page, file upload/job enqueueing, and missing file handling.
- Added layout navigation coverage.

## Verification

Verified inside the Docker web container:

```bash
bin/rails test
bin/rubocop
```

Latest verification results:

- `26 runs, 77 assertions, 0 failures, 0 errors, 0 skips`
- `53 files inspected, no offenses detected`
