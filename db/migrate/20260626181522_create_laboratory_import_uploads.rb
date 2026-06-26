class CreateLaboratoryImportUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :laboratory_import_uploads do |t|
      t.timestamps
    end
  end
end
