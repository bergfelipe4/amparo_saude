module Patients
  # Acha o paciente pelo telefone do WhatsApp ou cadastra um novo — mesmos
  # campos que o cadastro manual usa (PatientsController::REGISTRATION_FIELDS).
  class FindOrRegister
    def self.call(...) = new(...).call

    def initialize(organization:, phone:, attributes: {})
      @organization = organization
      @phone = phone.to_s.strip
      @attributes = attributes.symbolize_keys.slice(*PatientsController::REGISTRATION_FIELDS)
    end

    # Retorna o Patient — existente, ou um novo (persistido se os dados
    # informados forem suficientes; com .errors se não).
    def call
      existing = @organization.patients.find_by(phone: @phone)
      return existing if existing

      @organization.patients.new(@attributes.merge(phone: @phone)).tap(&:save)
    end
  end
end
