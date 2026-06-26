class LaboratoryImport
  include Mongoid::Document
  include Mongoid::Timestamps

  STATUSES = %w[pending processing completed failed].freeze

  field :original_filename, type: String
  field :upload_id, type: Integer
  field :status, type: String, default: "pending"
  field :error_message, type: String
  field :processed_at, type: Time
  field :patients_count, type: Integer, default: 0
  field :assessments_count, type: Integer, default: 0
  field :observations_count, type: Integer, default: 0

  validates :original_filename, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { desc(:created_at) }

  def upload
    @upload ||= LaboratoryImportUpload.find_by(id: upload_id) if upload_id
  end

  def file
    upload&.file
  end

  def file_content
    raise "Uploaded file is missing" unless file&.attached?

    file.download.force_encoding(Encoding::UTF_8)
  end
end
