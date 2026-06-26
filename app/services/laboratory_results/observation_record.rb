# typed: true

module LaboratoryResults
  class ObservationRecord < T::Struct
    const :name, String
    const :code, String
    const :value, Float
    const :units, String
  end
end
