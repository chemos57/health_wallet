require "test_helper"

class LaboratoryResults::ParserTest < ActiveSupport::TestCase
  test "parses one assessment with observations" do
    content = <<~HL7
      John Doe|1985-03-15|M|REF-2024-001
      8480-6|120|mmHg
      8462-4|80|mmHg
    HL7

    result = LaboratoryResults::Parser.call(content)

    assert result.success?
    parsed_file = result.value!
    assert_equal 1, parsed_file.assessments.length

    assessment = parsed_file.assessments.first
    assert_equal "John Doe", assessment.patient_name
    assert_equal Date.new(1985, 3, 15), assessment.patient_dob
    assert_equal "Male", assessment.patient_sex_at_birth
    assert_equal "REF-2024-001", assessment.reference
    assert_equal 2, assessment.observations.length
    assert_equal "Blood Pressure (Systolic)", assessment.observations.first.name
    assert_equal 120.0, assessment.observations.first.value
  end

  test "parses multiple assessments in one file" do
    content = <<~HL7
      John Doe|1985-03-15|M|REF-2024-003
      2093-3|190|mg/dL
      Jane Smith|1990-07-22|F|REF-2024-004
      8480-6|118|mmHg
      8462-4|78|mmHg
    HL7

    result = LaboratoryResults::Parser.call(content)

    assert result.success?
    parsed_file = result.value!
    assert_equal 2, parsed_file.assessments.length
    assert_equal [ "REF-2024-003", "REF-2024-004" ], parsed_file.assessments.map(&:reference)
    assert_equal [ 1, 2 ], parsed_file.assessments.map { |assessment| assessment.observations.length }
  end

  test "fails when an observation appears before an assessment header" do
    result = LaboratoryResults::Parser.call("8480-6|120|mmHg\n")

    assert result.failure?
    assert_match "line 1", result.failure.message
  end

  test "fails when an observation code is not supported" do
    content = <<~HL7
      John Doe|1985-03-15|M|REF-2024-001
      9999-9|120|mmHg
    HL7

    result = LaboratoryResults::Parser.call(content)

    assert result.failure?
    assert_match "Unsupported observation code 9999-9", result.failure.message
  end

  test "fails when an observation result is not numeric" do
    content = <<~HL7
      John Doe|1985-03-15|M|REF-2024-001
      8480-6|high|mmHg
    HL7

    result = LaboratoryResults::Parser.call(content)

    assert result.failure?
    assert_match "line 2", result.failure.message
  end
end
