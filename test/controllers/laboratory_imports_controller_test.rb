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
    file.write <<~HL7
      John Doe|1985-03-15|M|REF-2024-001
      8480-6|120|mmHg
    HL7
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
    assert_equal "", import.content
  ensure
    file.close
    file.unlink
  end
end
