ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...

    # Clean up MongoDB before each test
    setup do
      Mongoid.purge!
      clear_active_storage!
    end

    private

    def clear_active_storage!
      ActiveStorage::Attachment.delete_all if ActiveStorage::Attachment.table_exists?
      ActiveStorage::Blob.delete_all if ActiveStorage::Blob.table_exists?
      LaboratoryImportUpload.delete_all if LaboratoryImportUpload.table_exists?

      storage_path = Rails.root.join("tmp/storage")
      FileUtils.mkdir_p(storage_path)
      Dir.children(storage_path).each do |entry|
        FileUtils.rm_rf(storage_path.join(entry)) unless entry == ".keep"
      end
    end
  end
end
