# Summary of Changes

## Laboratory Results Import

- Added upload/status pages for simplified HL7 laboratory result files.
- Added `LaboratoryImport` Mongoid records to track import metadata, status, error messages, processed timestamps, and import counters.
- Added Active Storage-backed file storage through `LaboratoryImportUpload`.
- Added `LaboratoryImportJob` to process uploaded files in the background.
- Added routes for `laboratory_imports#index`, `new`, `create`, and `show`.
- Added bottom navigation links so users can move between Patients and Imports from every page.

## Storage Decisions

- Uploaded laboratory files are stored with Active Storage instead of as raw Mongoid document fields.
- `LaboratoryImport` keeps only metadata and an `upload_id`, while `LaboratoryImportUpload` is a small Active Record bridge model with `has_one_attached :file`.
- This bridge is necessary because the app's domain models use Mongoid, while Rails Active Storage is built around Active Record attachments.
- The split keeps potentially large file contents out of MongoDB and leaves Mongoid focused on domain/import status data.
- If `LaboratoryImport.create!` fails after an upload is created, the controller purges the Active Storage file and destroys the bridge row to avoid orphaned blobs.
- Existing local records from the earlier implementation that only have `content` and no `upload_id` are intentionally not supported for reprocessing.

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
- Import summaries count persisted patients, assessments, and unique observation records touched by the import, not raw input rows. This avoids over-counting when repeated observation codes update the same embedded observation.
- Empty uploaded files are stored and queued normally so the parser can return the same clean `File is empty` validation failure as other parse errors.

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
- Added importer tests for creating records, updating existing observations, and reporting persisted observation counts after upserts.
- Added job tests for completed imports, failed imports, top-level service constant lookup, and empty attached files.
- Added controller tests for upload page, Active Storage-backed file upload/job enqueueing, missing file handling, empty file upload, and upload cleanup when import record creation fails.
- Added layout navigation coverage.

## Verification

Verified inside the Docker web container:

```bash
bin/rails test
bin/rubocop
```

Latest verification results:

- `30 runs, 98 assertions, 0 failures, 0 errors, 0 skips`
- `57 files inspected, no offenses detected`
