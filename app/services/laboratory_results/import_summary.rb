# typed: true

module LaboratoryResults
  class ImportSummary < T::Struct
    const :patients, Integer
    const :assessments, Integer
    const :observations, Integer
  end
end
