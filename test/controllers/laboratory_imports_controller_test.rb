require "test_helper"

class LaboratoryImportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "should get new" do
    get new_laboratory_import_url

    assert_response :success
    assert_match "Upload Laboratory Results", response.body
  end

  test "creates a pending import and enqueues processing job" do
    file = Tempfile.new([ "john_doe", ".txt" ])
    content = <<~HL7
      John Doe|1985-03-15|M|REF-2024-001
      8480-6|120|mmHg
    HL7
    file.write content
    file.rewind

    assert_enqueued_with(job: LaboratoryImportJob) do
      post laboratory_imports_url, params: {
        laboratory_import: {
          file: Rack::Test::UploadedFile.new(file.path, "text/plain", original_filename: "John_Doe_HL7.txt")
        }
      }
    end

    import = LaboratoryImport.last
    assert_redirected_to laboratory_import_url(import)
    assert_equal "pending", import.status
    assert_equal "John_Doe_HL7.txt", import.original_filename
    assert import.file.attached?
    assert_equal content, import.file.download
    assert_not import.respond_to?(:content)
  ensure
    file.close
    file.unlink
  end

  test "does not create an import without a file" do
    assert_no_difference "LaboratoryImport.count" do
      post laboratory_imports_url, params: { laboratory_import: {} }
    end

    assert_response :unprocessable_entity
    assert_match "Choose a file", response.body
  end

  test "creates an import for an empty uploaded file so parsing can fail cleanly" do
    file = Tempfile.new([ "empty", ".txt" ])

    assert_enqueued_with(job: LaboratoryImportJob) do
      post laboratory_imports_url, params: {
        laboratory_import: {
          file: Rack::Test::UploadedFile.new(file.path, "text/plain", original_filename: "empty.txt")
        }
      }
    end

    import = LaboratoryImport.last
    assert_redirected_to laboratory_import_url(import)
    assert_equal "pending", import.status
    assert import.file.attached?
    assert_equal "", import.file.download
    assert_not import.respond_to?(:content)
  ensure
    file.close
    file.unlink
  end

  test "cleans up uploaded file when import record creation fails" do
    file = Tempfile.new([ "john_doe", ".txt" ])
    file.write <<~HL7
      John Doe|1985-03-15|M|REF-2024-001
      8480-6|120|mmHg
    HL7
    file.rewind

    original_create = LaboratoryImport.method(:create!)
    LaboratoryImport.define_singleton_method(:create!) { |**| raise "Import creation failed" }

    assert_raises(RuntimeError) do
      post laboratory_imports_url, params: {
        laboratory_import: {
          file: Rack::Test::UploadedFile.new(file.path, "text/plain", original_filename: "John_Doe_HL7.txt")
        }
      }
    end

    assert_equal 0, LaboratoryImportUpload.count
    assert_equal 0, ActiveStorage::Attachment.count
    assert_equal 0, ActiveStorage::Blob.count
  ensure
    LaboratoryImport.define_singleton_method(:create!) { |*args, **kwargs, &block| original_create.call(*args, **kwargs, &block) } if original_create
    file.close
    file.unlink
  end
end
