require "test_helper"

class LaboratoryImportJobTest < ActiveJob::TestCase
  test "marks the import completed and stores imported counters" do
    import = LaboratoryImport.create!(
      original_filename: "John_Doe_HL7.txt",
      content: <<~HL7,
        John Doe|1985-03-15|M|REF-2024-001
        8480-6|120|mmHg
      HL7
      status: "pending"
    )

    LaboratoryImportJob.perform_now(import.id.to_s)

    import.reload
    assert_equal "completed", import.status
    assert_equal 1, import.patients_count
    assert_equal 1, import.assessments_count
    assert_equal 1, import.observations_count
    assert_not_nil import.processed_at
    assert Patient.find_by(name: "John Doe", dob: Date.new(1985, 3, 15), sex_at_birth: "Male")
  end

  test "marks the import failed when parsing fails" do
    import = LaboratoryImport.create!(
      original_filename: "bad.txt",
      content: "8480-6|120|mmHg\n",
      status: "pending"
    )

    LaboratoryImportJob.perform_now(import.id.to_s)

    import.reload
    assert_equal "failed", import.status
    assert_match "line 1", import.error_message
    assert_not_nil import.processed_at
  end

  test "uses the top level laboratory results services" do
    LaboratoryImportJob.const_set(:LaboratoryResults, Module.new)
    import = LaboratoryImport.create!(
      original_filename: "John_Doe_HL7.txt",
      content: <<~HL7,
        John Doe|1985-03-15|M|REF-2024-001
        8480-6|120|mmHg
      HL7
      status: "pending"
    )

    LaboratoryImportJob.perform_now(import.id.to_s)

    import.reload
    assert_equal "completed", import.status
  ensure
    LaboratoryImportJob.send(:remove_const, :LaboratoryResults) if LaboratoryImportJob.const_defined?(:LaboratoryResults, false)
  end
end
