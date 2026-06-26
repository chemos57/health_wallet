# typed: true

module LaboratoryResults
  class ParsedFile < T::Struct
    const :assessments, T::Array[AssessmentRecord]
  end
end
