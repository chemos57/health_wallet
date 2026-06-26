# typed: true

require "dry/monads"

module LaboratoryResults
  class Parser
    extend T::Sig
    include Dry::Monads[:result]

    sig { params(content: String).returns(T.untyped) }
    def self.call(content)
      new.call(content)
    end

    sig { params(content: String).returns(T.untyped) }
    def call(content)
      assessment_attributes = T.let([], T::Array[T::Hash[Symbol, T.untyped]])
      current_assessment = T.let(nil, T.nilable(T::Hash[Symbol, T.untyped]))

      lines = normalized_lines(content)
      return failure("File is empty") if lines.empty?

      lines.each do |line_number, line|
        parts = line.split("|", -1).map(&:strip)

        case parts.length
        when 4
          assessment_attributes << current_assessment if current_assessment
          current_assessment = parse_assessment_header(parts, line_number)
          return current_assessment if current_assessment.failure?

          current_assessment = current_assessment.value!
        when 3
          return failure("Observation found before assessment header on line #{line_number}") unless current_assessment

          observation = parse_observation(parts, line_number)
          return observation if observation.failure?

          current_assessment.fetch(:observations) << observation.value!
        else
          return failure("Invalid simplified HL7 line #{line_number}: expected 3 or 4 pipe-delimited fields")
        end
      end

      assessment_attributes << current_assessment if current_assessment
      return failure("File does not contain any assessment headers") if assessment_attributes.empty?

      Success(ParsedFile.new(assessments: assessment_attributes.map { |attributes| build_assessment(attributes) }))
    end

    private

    sig { params(content: String).returns(T::Array[T.untyped]) }
    def normalized_lines(content)
      content.lines.each_with_index.filter_map do |line, index|
        normalized = line.strip
        [ index + 1, normalized ] unless normalized.empty?
      end
    end

    sig { params(parts: T::Array[String], line_number: Integer).returns(T.untyped) }
    def parse_assessment_header(parts, line_number)
      patient_name, dob_text, sex_text, reference = parts
      return failure("Patient name is missing on line #{line_number}") if patient_name.blank?
      return failure("Assessment reference is missing on line #{line_number}") if reference.blank?

      dob = parse_date(dob_text, line_number)
      return dob if dob.failure?

      sex = normalize_sex_at_birth(sex_text, line_number)
      return sex if sex.failure?

      Success({
        patient_name: patient_name,
        patient_dob: dob.value!,
        patient_sex_at_birth: sex.value!,
        reference: reference,
        observations: []
      })
    end

    sig { params(parts: T::Array[String], line_number: Integer).returns(T.untyped) }
    def parse_observation(parts, line_number)
      code, result_text, units = parts
      description = ObservationCatalog.description_for(code)
      return failure("Unsupported observation code #{code} on line #{line_number}") unless description
      return failure("Observation units are missing on line #{line_number}") if units.blank?

      value = parse_float(result_text, line_number)
      return value if value.failure?

      Success(ObservationRecord.new(
        name: description,
        code: code,
        value: value.value!,
        units: units
      ))
    end

    sig { params(text: String, line_number: Integer).returns(T.untyped) }
    def parse_date(text, line_number)
      Success(Date.iso8601(text))
    rescue Date::Error
      failure("Invalid patient date of birth on line #{line_number}: #{text}")
    end

    sig { params(text: String, line_number: Integer).returns(T.untyped) }
    def parse_float(text, line_number)
      Success(Float(text))
    rescue ArgumentError
      failure("Invalid observation result on line #{line_number}: #{text}")
    end

    sig { params(text: String, line_number: Integer).returns(T.untyped) }
    def normalize_sex_at_birth(text, line_number)
      case text.strip.downcase
      when "m", "male"
        Success("Male")
      when "f", "female"
        Success("Female")
      else
        failure("Invalid patient sex at birth on line #{line_number}: #{text}")
      end
    end

    sig { params(attributes: T::Hash[Symbol, T.untyped]).returns(AssessmentRecord) }
    def build_assessment(attributes)
      AssessmentRecord.new(
        patient_name: attributes.fetch(:patient_name),
        patient_dob: attributes.fetch(:patient_dob),
        patient_sex_at_birth: attributes.fetch(:patient_sex_at_birth),
        reference: attributes.fetch(:reference),
        observations: attributes.fetch(:observations)
      )
    end

    sig { params(message: String).returns(T.untyped) }
    def failure(message)
      Failure(ImportFailure.new(message: message))
    end
  end
end
