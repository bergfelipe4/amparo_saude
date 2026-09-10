module Patients
  # Localiza o dono de uma conversa sem depender da formatação usada no
  # cadastro. JIDs @lid não são números de telefone reais e, por segurança,
  # só podem ser associados por igualdade exata.
  class FindByPhone
    def self.call(...) = new(...).call

    def initialize(organization:, phone:)
      @organization = organization
      @phone = phone.to_s.strip
    end

    def call
      return if @phone.blank?

      @organization.patients.where.not(phone: [ nil, "" ]).find do |patient|
        equivalent?(patient.phone, @phone)
      end
    end

    private

    def equivalent?(left, right)
      left_keys = lookup_keys(left)
      right_keys = lookup_keys(right)
      left_keys.present? && (left_keys & right_keys).present?
    end

    def lookup_keys(value)
      raw = value.to_s.strip.downcase
      return [] if raw.blank?
      return [ "jid:#{raw}" ] if raw.end_with?("@lid")

      digits = raw.gsub(/\D/, "")
      return [] if digits.blank?

      [ digits, brazilian_variant(digits) ].compact.uniq
    end

    def brazilian_variant(digits)
      if digits.start_with?("55") && [ 12, 13 ].include?(digits.length)
        digits.delete_prefix("55")
      elsif [ 10, 11 ].include?(digits.length)
        "55#{digits}"
      end
    end
  end
end
