# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_11_024739) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "appointment_permissions", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.datetime "created_at", null: false
    t.bigint "granted_by_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["appointment_id", "user_id"], name: "index_appointment_permissions_on_appointment_and_user", unique: true
    t.index ["appointment_id"], name: "index_appointment_permissions_on_appointment_id"
    t.index ["granted_by_id"], name: "index_appointment_permissions_on_granted_by_id"
    t.index ["user_id"], name: "index_appointment_permissions_on_user_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.string "appointment_type", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.datetime "ends_at", null: false
    t.bigint "follow_up_of_id"
    t.bigint "organization_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "professional_id", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "aguardando", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_appointments_on_created_by_id"
    t.index ["follow_up_of_id"], name: "index_appointments_on_follow_up_of_id"
    t.index ["organization_id"], name: "index_appointments_on_organization_id"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["professional_id"], name: "index_appointments_on_professional_id"
    t.index ["unit_id", "starts_at"], name: "index_appointments_on_unit_id_and_starts_at"
    t.index ["unit_id"], name: "index_appointments_on_unit_id"
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.text "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "conversations", force: :cascade do |t|
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "last_message_at"
    t.bigint "organization_id", null: false
    t.bigint "patient_id"
    t.string "phone_number", null: false
    t.string "status", default: "aberta", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "phone_number"], name: "index_conversations_on_organization_id_and_phone_number"
    t.index ["organization_id"], name: "index_conversations_on_organization_id"
    t.index ["patient_id"], name: "index_conversations_on_patient_id"
  end

  create_table "encounters", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.text "assessment"
    t.string "blood_pressure"
    t.text "chief_complaint"
    t.datetime "created_at", null: false
    t.jsonb "custom_fields"
    t.string "diagnosis"
    t.integer "heart_rate"
    t.decimal "height_cm", precision: 5, scale: 1
    t.text "objective"
    t.bigint "patient_id", null: false
    t.text "plan"
    t.bigint "professional_id", null: false
    t.text "subjective"
    t.decimal "temperature", precision: 4, scale: 1
    t.datetime "updated_at", null: false
    t.decimal "weight_kg", precision: 5, scale: 1
    t.index ["appointment_id"], name: "index_encounters_on_appointment_id"
    t.index ["patient_id"], name: "index_encounters_on_patient_id"
    t.index ["professional_id"], name: "index_encounters_on_professional_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.jsonb "tool_calls"
    t.jsonb "tool_result"
    t.string "whatsapp_message_id"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["whatsapp_message_id"], name: "index_messages_on_whatsapp_message_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.boolean "ai_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.string "whatsapp_connection_status", default: "nao_iniciado", null: false
    t.string "whatsapp_number"
    t.string "whatsapp_session_id"
    t.string "whatsapp_token"
    t.index ["whatsapp_number"], name: "index_organizations_on_whatsapp_number", unique: true
  end

  create_table "patients", force: :cascade do |t|
    t.string "address"
    t.string "allergy"
    t.date "birth_date"
    t.string "blood_type"
    t.string "carteirinha"
    t.text "chronic_conditions"
    t.string "convenio"
    t.string "cpf"
    t.datetime "created_at", null: false
    t.text "current_medications"
    t.jsonb "custom_fields"
    t.string "email"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.text "family_history"
    t.string "guardian_name"
    t.string "name"
    t.bigint "organization_id", null: false
    t.string "phone"
    t.string "sex"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_patients_on_organization_id"
    t.index ["phone"], name: "index_patients_on_phone"
  end

  create_table "prescription_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dosage"
    t.string "duration"
    t.string "frequency"
    t.text "instructions"
    t.string "medication_name"
    t.integer "position"
    t.bigint "prescription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["prescription_id"], name: "index_prescription_items_on_prescription_id"
  end

  create_table "prescriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "encounter_id", null: false
    t.datetime "issued_at"
    t.text "notes"
    t.bigint "organization_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "professional_id", null: false
    t.datetime "updated_at", null: false
    t.index ["encounter_id"], name: "index_prescriptions_on_encounter_id"
    t.index ["organization_id"], name: "index_prescriptions_on_organization_id"
    t.index ["patient_id"], name: "index_prescriptions_on_patient_id"
    t.index ["professional_id"], name: "index_prescriptions_on_professional_id"
  end

  create_table "professionals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "crm"
    t.string "name"
    t.bigint "organization_id", null: false
    t.string "specialty"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_professionals_on_organization_id"
    t.index ["unit_id"], name: "index_professionals_on_unit_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "address"
    t.integer "closes_at_minutes", default: 1080, null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "opens_at_minutes", default: 480, null: false
    t.bigint "organization_id", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.integer "working_days", default: [1, 2, 3, 4, 5], null: false, array: true
    t.index ["organization_id"], name: "index_units_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "password_digest", null: false
    t.bigint "professional_id"
    t.string "role", default: "recepcao", null: false
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["professional_id"], name: "index_users_on_professional_id"
    t.index ["unit_id"], name: "index_users_on_unit_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "appointment_permissions", "appointments"
  add_foreign_key "appointment_permissions", "users"
  add_foreign_key "appointment_permissions", "users", column: "granted_by_id"
  add_foreign_key "appointments", "appointments", column: "follow_up_of_id"
  add_foreign_key "appointments", "organizations"
  add_foreign_key "appointments", "patients"
  add_foreign_key "appointments", "professionals"
  add_foreign_key "appointments", "units"
  add_foreign_key "appointments", "users", column: "created_by_id"
  add_foreign_key "conversations", "organizations"
  add_foreign_key "conversations", "patients"
  add_foreign_key "encounters", "appointments"
  add_foreign_key "encounters", "patients"
  add_foreign_key "encounters", "professionals"
  add_foreign_key "messages", "conversations"
  add_foreign_key "patients", "organizations"
  add_foreign_key "prescription_items", "prescriptions"
  add_foreign_key "prescriptions", "encounters"
  add_foreign_key "prescriptions", "organizations"
  add_foreign_key "prescriptions", "patients"
  add_foreign_key "prescriptions", "professionals"
  add_foreign_key "professionals", "organizations"
  add_foreign_key "professionals", "units"
  add_foreign_key "units", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "professionals"
  add_foreign_key "users", "units"
end
