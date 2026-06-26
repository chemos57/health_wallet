# typed: true

module LaboratoryResults
  module ObservationCatalog
    extend T::Sig

    DESCRIPTIONS = T.let({
      "8480-6" => "Blood Pressure (Systolic)",
      "8462-4" => "Blood Pressure (Diastolic)",
      "8867-4" => "Heart Rate",
      "8310-5" => "Body Temperature",
      "9279-1" => "Respiratory Rate",
      "2708-6" => "Oxygen Saturation",
      "29463-7" => "Body Weight",
      "8302-2" => "Body Height",
      "2339-0" => "Blood Glucose",
      "2093-3" => "Cholesterol"
    }.freeze, T::Hash[String, String])

    sig { params(code: String).returns(T.nilable(String)) }
    def self.description_for(code)
      DESCRIPTIONS[code]
    end
  end
end
