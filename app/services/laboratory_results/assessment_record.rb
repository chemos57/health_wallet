# typed: true

module LaboratoryResults
  class AssessmentRecord < T::Struct
    const :patient_name, String
    const :patient_dob, Date
    const :patient_sex_at_birth, String
    const :reference, String
    const :observations, T::Array[ObservationRecord]
  end
end
