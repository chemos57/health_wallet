class LaboratoryImportJob < ApplicationJob
  def perform(laboratory_import_id)
    laboratory_import = LaboratoryImport.find(laboratory_import_id)
    laboratory_import.update!(status: "processing", error_message: nil)

    parse_result = ::LaboratoryResults::Parser.call(laboratory_import.file_content)
    return mark_failed(laboratory_import, parse_result.failure.message) if parse_result.failure?

    import_result = ::LaboratoryResults::Importer.call(parse_result.value!)
    return mark_failed(laboratory_import, import_result.failure.message) if import_result.failure?

    summary = import_result.value!
    laboratory_import.update!(
      status: "completed",
      patients_count: summary.patients,
      assessments_count: summary.assessments,
      observations_count: summary.observations,
      processed_at: Time.current
    )
  rescue StandardError => error
    mark_failed(laboratory_import, error.message) if laboratory_import
  end

  private

  def mark_failed(laboratory_import, message)
    laboratory_import.update!(
      status: "failed",
      error_message: message,
      processed_at: Time.current
    )
  end
end
