class AppointmentPermission < ApplicationRecord
  audited associated_with: :appointment

  belongs_to :appointment
  belongs_to :user
  belongs_to :granted_by, class_name: "User"

  validates :user_id, uniqueness: { scope: :appointment_id }
end
