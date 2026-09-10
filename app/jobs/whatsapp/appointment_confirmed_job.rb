module Whatsapp
  # Avisa no mesmo WhatsApp que originou o agendamento quando o profissional
  # responsável confirma uma consulta criada pela secretária de IA.
  class AppointmentConfirmedJob < ApplicationJob
    queue_as :whatsapp

    class DeliveryError < StandardError; end

    retry_on Faraday::Error, DeliveryError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveRecord::RecordNotFound

    def perform(appointment_id)
      appointment = Appointment.includes(:conversation, :patient, :professional, :created_by, :organization)
                               .find(appointment_id)
      return unless deliverable?(appointment)

      appointment.with_lock do
        appointment.reload
        return unless deliverable?(appointment)

        message = confirmation_message(appointment)
        conversation = appointment.conversation
        organization = appointment.organization
        delivered = Whatsapp::Client.build.send_message(
          session: organization.whatsapp_session,
          token: organization.whatsapp_token,
          phone: conversation.phone_number,
          message: message
        )
        raise DeliveryError, "WPPConnect não confirmou o envio" unless delivered

        conversation.messages.create!(role: "assistant", content: message)
        conversation.update!(last_message_at: Time.current)
        appointment.update_column(:whatsapp_confirmation_sent_at, Time.current)
      end
    end

    private

    def deliverable?(appointment)
      appointment.status == "confirmado" &&
        appointment.created_by&.ia? &&
        appointment.conversation.present? &&
        appointment.whatsapp_confirmation_sent_at.blank?
    end

    def confirmation_message(appointment)
      conversation = appointment.conversation
      sender_first_name = conversation.patient&.name.to_s.split.first
      greeting = sender_first_name.present? ? "Olá, #{sender_first_name}! " : ""
      subject = if conversation.patient_id == appointment.patient_id
        "Sua consulta"
      else
        "A consulta de #{appointment.patient.name}"
      end

      "#{greeting}#{subject} com #{appointment.professional.name}, em #{appointment.starts_at.strftime('%d/%m/%Y às %H:%M')}, foi confirmada pelo profissional responsável. Está tudo certo para o atendimento."
    end
  end
end
