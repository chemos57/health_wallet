class LaboratoryImportsController < ApplicationController
  def index
    @laboratory_imports = LaboratoryImport.recent.limit(25)
  end

  def new
    @laboratory_import = LaboratoryImport.new
  end

  def create
    file = uploaded_file

    unless file
      @laboratory_import = LaboratoryImport.new
      @error = "Choose a file to upload."
      return render :new, status: :unprocessable_entity
    end

    upload = LaboratoryImportUpload.create!(file: file)

    laboratory_import = LaboratoryImport.create!(
      original_filename: file.original_filename,
      upload_id: upload.id,
      status: "pending"
    )

    LaboratoryImportJob.perform_later(laboratory_import.id.to_s)
    redirect_to laboratory_import_path(laboratory_import), notice: "Laboratory import queued."
  rescue StandardError
    cleanup_upload(upload)
    raise
  end

  def show
    @laboratory_import = LaboratoryImport.find(params[:id])
  end

  private

  def uploaded_file
    params.dig(:laboratory_import, :file)
  end

  def cleanup_upload(upload)
    return unless upload

    upload.file.purge if upload.file.attached?
    upload.destroy!
  rescue StandardError => error
    Rails.logger.warn("Failed to clean up laboratory import upload #{upload&.id}: #{error.message}")
  end
end
