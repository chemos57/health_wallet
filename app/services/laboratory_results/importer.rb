# typed: true

require "dry/monads"
require "set"

module LaboratoryResults
  class Importer
    extend T::Sig
    include Dry::Monads[:result]

    sig { params(parsed_file: ParsedFile).returns(T.untyped) }
    def self.call(parsed_file)
      new.call(parsed_file)
    end

    sig { params(parsed_file: ParsedFile).returns(T.untyped) }
    def call(parsed_file)
      patient_keys = Set.new
      assessment_keys = Set.new
      observations_count = 0

      parsed_file.assessments.each do |assessment_record|
        patient = find_or_create_patient(assessment_record)
        assessment = find_or_create_assessment(patient, assessment_record)

        patient_keys << patient.id.to_s
        assessment_keys << assessment.id.to_s

        assessment_record.observations.each do |observation_record|
          upsert_observation(assessment, observation_record)
          observations_count += 1
        end
      end

      Success(ImportSummary.new(
        patients: patient_keys.length,
        assessments: assessment_keys.length,
        observations: observations_count
      ))
    rescue StandardError => error
      Failure(ImportFailure.new(message: "Import failed: #{error.message}"))
    end

    private

    sig { params(record: AssessmentRecord).returns(Patient) }
    def find_or_create_patient(record)
      Patient.find_or_create_by!(
        name: record.patient_name,
        dob: record.patient_dob,
        sex_at_birth: record.patient_sex_at_birth
      )
    end

    sig { params(patient: Patient, record: AssessmentRecord).returns(Assessment) }
    def find_or_create_assessment(patient, record)
      patient.assessments.where(reference: record.reference).first ||
        patient.assessments.create!(reference: record.reference, date: Date.current.to_s)
    end

    sig { params(assessment: Assessment, record: ObservationRecord).void }
    def upsert_observation(assessment, record)
      observation = assessment.observations.find { |existing| existing.code == record.code }

      if observation
        observation.update!(name: record.name, value: record.value, units: record.units)
      else
        assessment.observations.create!(
          name: record.name,
          code: record.code,
          value: record.value,
          units: record.units
        )
      end
    end
  end
end
