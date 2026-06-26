class LaboratoryImport
  include Mongoid::Document
  include Mongoid::Timestamps

  STATUSES = %w[pending processing completed failed].freeze

  field :original_filename, type: String
  field :content, type: String
  field :status, type: String, default: "pending"
  field :error_message, type: String
  field :processed_at, type: Time
  field :patients_count, type: Integer, default: 0
  field :assessments_count, type: Integer, default: 0
  field :observations_count, type: Integer, default: 0

  validates :original_filename, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { desc(:created_at) }
end
