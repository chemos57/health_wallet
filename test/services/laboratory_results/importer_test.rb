require "test_helper"

class LaboratoryResults::ImporterTest < ActiveSupport::TestCase
  test "creates patients assessments and observations from parsed results" do
    parsed_file = LaboratoryResults::Parser.call(<<~HL7).value!
      John Doe|1985-03-15|M|REF-2024-001
      8480-6|120|mmHg
      8462-4|80|mmHg
    HL7

    result = LaboratoryResults::Importer.call(parsed_file)

    assert result.success?
    summary = result.value!
    assert_equal 1, summary.patients
    assert_equal 1, summary.assessments
    assert_equal 2, summary.observations

    patient = Patient.find_by(name: "John Doe", dob: Date.new(1985, 3, 15), sex_at_birth: "Male")
    assert patient
    assessment = patient.assessments.find_by(reference: "REF-2024-001")
    assert assessment
    assert_equal 2, assessment.observations.count
    assert_equal 120.0, assessment.observations.find { |observation| observation.code == "8480-6" }.value
  end

  test "updates existing observations by code within the matching assessment" do
    patient = Patient.create!(name: "John Doe", dob: Date.new(1985, 3, 15), sex_at_birth: "Male")
    assessment = patient.assessments.create!(date: "2026-01-01", reference: "REF-2024-001")
    assessment.observations.create!(
      name: "Blood Pressure (Systolic)",
      code: "8480-6",
      value: 110.0,
      units: "mmHg"
    )

    parsed_file = LaboratoryResults::Parser.call(<<~HL7).value!
      John Doe|1985-03-15|M|REF-2024-001
      8480-6|125|mmHg
    HL7

    result = LaboratoryResults::Importer.call(parsed_file)

    assert result.success?
    assessment.reload
    assert_equal 1, assessment.observations.count
    assert_equal 125.0, assessment.observations.first.value
  end
end
