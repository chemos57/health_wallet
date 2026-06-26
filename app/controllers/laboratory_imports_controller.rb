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

    laboratory_import = LaboratoryImport.create!(
      original_filename: file.original_filename,
      content: file.read.force_encoding(Encoding::UTF_8),
      status: "pending"
    )

    LaboratoryImportJob.perform_later(laboratory_import.id.to_s)
    redirect_to laboratory_import_path(laboratory_import), notice: "Laboratory import queued."
  end

  def show
    @laboratory_import = LaboratoryImport.find(params[:id])
  end

  private

  def uploaded_file
    params.dig(:laboratory_import, :file)
  end
end
