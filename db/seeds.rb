# Idempotent seed for the Amparo Saúde prototype domain.
# Mirrors the data used in the visual prototype so the real UI can be compared 1:1.

PASSWORD = "amparo123"

# The audited gem would otherwise auto-log every seed write with today's timestamp,
# clashing with the hand-crafted historical trail created via audit! below.
Audited.auditing_enabled = false

def audit!(record, action:, actor:, changes: {}, at:)
  # `actor` can be a User record or a plain String (e.g. "Sistema (WhatsApp)") —
  # Audited::Audit#user= handles both via user_as_string=.
  Audited::Audit.create!(
    auditable: record,
    action: action,
    audited_changes: changes,
    user: actor,
    created_at: at
  )
end

organization = Organization.find_or_create_by!(slug: "amparo-saude") do |o|
  o.name = "Amparo Saúde"
end

jardins = organization.units.find_or_create_by!(name: "Jardins") do |u|
  u.address = "Rua Peixoto Gomide, 1140 — Jardins, São Paulo/SP"
  u.phone = "(11) 3555-0192"
end

moema = organization.units.find_or_create_by!(name: "Moema") do |u|
  u.address = "Av. Ibirapuera, 2450 — Moema, São Paulo/SP"
  u.phone = "(11) 3555-0287"
end

camila = jardins.professionals.find_or_create_by!(name: "Dra. Camila Nogueira") do |p|
  p.organization = organization; p.specialty = "Clínica Geral"; p.crm = "CRM/SP 123.456"
end
rafael = jardins.professionals.find_or_create_by!(name: "Dr. Rafael Tavares") do |p|
  p.organization = organization; p.specialty = "Cardiologia"; p.crm = "CRM/SP 98.220"
end
beatriz = jardins.professionals.find_or_create_by!(name: "Dra. Beatriz Lins") do |p|
  p.organization = organization; p.specialty = "Pediatria"; p.crm = "CRM/SP 145.310"
end
henrique = jardins.professionals.find_or_create_by!(name: "Dr. Henrique Souza") do |p|
  p.organization = organization; p.specialty = "Ortopedia"; p.crm = "CRM/SP 77.884"
end
marcos = moema.professionals.find_or_create_by!(name: "Dr. Marcos Vidal") do |p|
  p.organization = organization; p.specialty = "Clínica Geral"; p.crm = "CRM/SP 110.774"
end
fernanda = moema.professionals.find_or_create_by!(name: "Dra. Fernanda Melo") do |p|
  p.organization = organization; p.specialty = "Ginecologia"; p.crm = "CRM/SP 132.981"
end

admin = organization.users.find_or_initialize_by(email: "admin@amparosaude.com.br")
admin.assign_attributes(name: "Administrador Amparo", role: "admin", password: PASSWORD)
admin.save!

felipe_admin = organization.users.find_or_initialize_by(email: "felipe4bfonseca@gmail.com")
felipe_admin.assign_attributes(name: "Felipe Fonseca", role: "admin", password: "12345678")
felipe_admin.save!

larissa = organization.users.find_or_initialize_by(email: "larissa@amparosaude.com.br")
larissa.assign_attributes(name: "Larissa Prado", role: "secretaria", unit: jardins, password: PASSWORD)
larissa.save!

renata = organization.users.find_or_initialize_by(email: "renata@amparosaude.com.br")
renata.assign_attributes(name: "Renata Alves", role: "secretaria", unit: moema, password: PASSWORD)
renata.save!

camila_user = organization.users.find_or_initialize_by(email: "camila@amparosaude.com.br")
camila_user.assign_attributes(name: camila.name, role: "medico", unit: jardins, professional: camila, password: PASSWORD)
camila_user.save!

rafael_user = organization.users.find_or_initialize_by(email: "rafael@amparosaude.com.br")
rafael_user.assign_attributes(name: rafael.name, role: "medico", unit: jardins, professional: rafael, password: PASSWORD)
rafael_user.save!

# ---------- Patients ----------
patients_data = [
  { name: "Mariana Costa Ribeiro", cpf: "111.222.333-16", sex: "Feminino", birth_date: Date.new(1992, 3, 12), phone: "(11) 98211-4470", email: "mariana.ribeiro@email.com", address: "Al. Lorena, 220 — Jardins, São Paulo/SP", convenio: "Unimed", carteirinha: "0034 552 118", allergy: "Dipirona",
    blood_type: "O+", chronic_conditions: "Enxaqueca crônica", current_medications: "Anticoncepcional oral (Yasmin)", family_history: "Mãe com hipertensão; avó paterna com enxaqueca", emergency_contact_name: "Paulo Ribeiro (marido)", emergency_contact_phone: "(11) 98877-1122" },
  { name: "Thiago Monteiro", cpf: "222.333.444-84", sex: "Masculino", birth_date: Date.new(1985, 11, 5), phone: "(11) 97744-2301", email: "thiago.monteiro@email.com", address: "R. Haddock Lobo, 595 — Jardins, São Paulo/SP", convenio: "Bradesco Saúde", carteirinha: "778 220 991", allergy: nil },
  { name: "Ana Beatriz Prates", cpf: "333.444.555-52", sex: "Feminino", birth_date: Date.new(1998, 7, 28), phone: "(11) 96622-1198", email: "ana.prates@email.com", address: "R. Oscar Freire, 1120 — Jardins, São Paulo/SP", convenio: "Particular", carteirinha: nil, allergy: nil },
  { name: "Eduardo Ferreira Lima", cpf: "444.555.666-07", sex: "Masculino", birth_date: Date.new(1979, 1, 19), phone: "(11) 98890-7712", email: "eduardo.lima@email.com", address: "R. Bela Cintra, 880 — Consolação, São Paulo/SP", convenio: "Unimed", carteirinha: "0034 118 902", allergy: "Penicilina",
    blood_type: "A+", chronic_conditions: "Bronquite crônica leve", current_medications: "Nenhuma medicação contínua", family_history: "Pai com asma", emergency_contact_name: "Renata Lima (esposa)", emergency_contact_phone: "(11) 98123-7788" },
  { name: "Patrícia Gomes", cpf: "555.666.777-63", sex: "Feminino", birth_date: Date.new(1990, 9, 2), phone: "(11) 99456-3320", email: "patricia.gomes@email.com", address: "R. Augusta, 2310 — Jardins, São Paulo/SP", convenio: "SulAmérica", carteirinha: "442 810 337", allergy: nil },
  { name: "Rogério Nascimento", cpf: "666.777.888-91", sex: "Masculino", birth_date: Date.new(1966, 6, 14), phone: "(11) 98123-5567", email: "rogerio.nasc@email.com", address: "R. Pamplona, 145 — Jardins, São Paulo/SP", convenio: "Particular", carteirinha: nil, allergy: nil },
  { name: "Roberto Nunes", cpf: "777.888.999-38", sex: "Masculino", birth_date: Date.new(1974, 4, 30), phone: "(11) 97012-8845", email: "roberto.nunes@email.com", address: "Av. Rebouças, 3040 — Pinheiros, São Paulo/SP", convenio: "Bradesco Saúde", carteirinha: "778 552 004", allergy: nil },
  { name: "Sofia Duarte", cpf: "888.999.000-20", sex: "Feminino", birth_date: Date.new(1997, 5, 3), phone: "(11) 98877-2201", email: "sofia.duarte@email.com", address: "R. Estados Unidos, 480 — Jardins, São Paulo/SP", convenio: "SulAmérica", carteirinha: "590 221 774", allergy: nil },
  { name: "Fernando Castro", cpf: "999.000.111-45", sex: "Masculino", birth_date: Date.new(1981, 2, 17), phone: "(11) 98341-9020", email: "fernando.castro@email.com", address: "Al. Santos, 900 — Jardins, São Paulo/SP", convenio: "Unimed", carteirinha: "0034 887 220", allergy: nil },
  { name: "Juliana Reis", cpf: "100.211.322-58", sex: "Feminino", birth_date: Date.new(1968, 8, 21), phone: "(11) 99120-3345", email: "juliana.reis@email.com", address: "R. Groenlândia, 700 — Jardins, São Paulo/SP", convenio: "Bradesco Saúde", carteirinha: "778 903 112", allergy: nil },
  { name: "Davi Ferreira", cpf: "211.322.433-04", sex: "Masculino", birth_date: Date.new(2022, 3, 9), phone: "(11) 98765-4321", email: nil, address: "R. Itacolomi, 300 — Jardins, São Paulo/SP", convenio: "Particular", carteirinha: nil, allergy: nil, guardian_name: "Camila Ferreira (mãe)" },
  { name: "Lívia Torres", cpf: "322.433.544-77", sex: "Feminino", birth_date: Date.new(2019, 10, 12), phone: "(11) 98654-3210", email: nil, address: "R. Sergipe, 210 — Higienópolis, São Paulo/SP", convenio: "Unimed", carteirinha: "0034 442 118", allergy: nil, guardian_name: "Marcos Torres (pai)" },
  { name: "Heitor Malta", cpf: "433.544.655-09", sex: "Masculino", birth_date: Date.new(2024, 1, 25), phone: "(11) 98543-2109", email: nil, address: "R. Bahia, 88 — Higienópolis, São Paulo/SP", convenio: "SulAmérica", carteirinha: "590 331 442", allergy: nil, guardian_name: "Bianca Malta (mãe)" },
  { name: "Cláudio Peixoto", cpf: "544.655.766-31", sex: "Masculino", birth_date: Date.new(1963, 12, 4), phone: "(11) 98432-1098", email: "claudio.peixoto@email.com", address: "R. Joaquim Floriano, 500 — Itaim Bibi, São Paulo/SP", convenio: "Particular", carteirinha: nil, allergy: nil },
  { name: "Beatriz Andrade", cpf: "655.766.877-82", sex: "Feminino", birth_date: Date.new(1987, 4, 8), phone: "(11) 98321-0987", email: "beatriz.andrade@email.com", address: "R. Cardeal Arcoverde, 220 — Pinheiros, São Paulo/SP", convenio: "Bradesco Saúde", carteirinha: "778 664 559", allergy: nil },
  { name: "Vinícius Andrade Ramos", cpf: "766.877.988-05", sex: "Masculino", birth_date: Date.new(1995, 6, 20), phone: "(11) 98211-6633", email: "vinicius.ramos@email.com", address: "R. Frei Caneca, 550 — Consolação, São Paulo/SP", convenio: "Unimed", carteirinha: "0034 771 220", allergy: nil },
  { name: "Isabela Martins Correia", cpf: "877.988.099-27", sex: "Feminino", birth_date: Date.new(2001, 12, 3), phone: "(11) 98765-1120", email: "isabela.correia@email.com", address: "R. Teodoro Sampaio, 1420 — Pinheiros, São Paulo/SP", convenio: "SulAmérica", carteirinha: "590 442 118", allergy: "Amoxicilina" },
]

patients = {}
patients_data.each do |data|
  p = organization.patients.find_or_initialize_by(cpf: data[:cpf])
  p.assign_attributes(data.except(:cpf))
  p.organization = organization
  p.save!
  patients[data[:name]] = p
end

# ---------- Retroactive change history (for Mariana, to showcase the audit trail) ----------
mariana = patients["Mariana Costa Ribeiro"]
if mariana.audits.count <= 1
  audit!(mariana, action: "create", actor: larissa, at: 30.weeks.ago)
  audit!(mariana, action: "update", actor: larissa, at: 20.weeks.ago,
         changes: { "phone" => ["(11) 98211-0022", "(11) 98211-4470"] })
  audit!(mariana, action: "update", actor: larissa, at: 8.weeks.ago,
         changes: { "convenio" => ["Particular", "Unimed"] })
  audit!(mariana, action: "update", actor: camila_user, at: 5.weeks.ago,
         changes: { "allergy" => [nil, "Dipirona"] })
end

# ---------- Today's appointments (Jardins) ----------
today = Date.current
def at(today, hh, mm) = Time.zone.local(today.year, today.month, today.day, hh, mm)

appt_data = [
  { prof: camila, patient: "Sofia Duarte", start: [8, 0], finish: [8, 30], type: "Retorno", status: "confirmado" },
  { prof: camila, patient: "Eduardo Ferreira Lima", start: [9, 0], finish: [9, 30], type: "Consulta", status: "concluido" },
  { prof: camila, patient: "Patrícia Gomes", start: [10, 0], finish: [10, 30], type: "Consulta", status: "aguardando" },
  { prof: camila, patient: "Rogério Nascimento", start: [11, 0], finish: [11, 30], type: "Retorno", status: "confirmado" },
  { prof: camila, patient: "Mariana Costa Ribeiro", start: [14, 0], finish: [14, 30], type: "Consulta", status: "atendimento" },
  { prof: rafael, patient: "Thiago Monteiro", start: [8, 30], finish: [9, 0], type: "Consulta", status: "aguardando" },
  { prof: rafael, patient: "Ana Beatriz Prates", start: [9, 30], finish: [10, 0], type: "Retorno", status: "confirmado" },
  { prof: rafael, patient: "Fernando Castro", start: [11, 0], finish: [12, 0], type: "Consulta", status: "confirmado" },
  { prof: rafael, patient: "Juliana Reis", start: [15, 30], finish: [16, 0], type: "Consulta", status: "concluido" },
  { prof: beatriz, patient: "Davi Ferreira", start: [8, 0], finish: [8, 30], type: "Consulta", status: "concluido" },
  { prof: beatriz, patient: "Lívia Torres", start: [10, 30], finish: [11, 0], type: "Retorno", status: "confirmado" },
  { prof: beatriz, patient: "Heitor Malta", start: [13, 30], finish: [14, 0], type: "Consulta", status: "aguardando" },
  { prof: henrique, patient: "Cláudio Peixoto", start: [9, 0], finish: [9, 40], type: "Consulta", status: "confirmado" },
  { prof: henrique, patient: "Roberto Nunes", start: [13, 0], finish: [13, 40], type: "Retorno", status: "faltou" },
  { prof: henrique, patient: "Beatriz Andrade", start: [16, 0], finish: [16, 40], type: "Consulta", status: "confirmado" },
  { prof: marcos, patient: "Cláudio Peixoto", start: [10, 0], finish: [10, 30], type: "Retorno", status: "confirmado" },
  { prof: fernanda, patient: "Beatriz Andrade", start: [11, 30], finish: [12, 0], type: "Consulta", status: "aguardando" },
]

soap_data = {
  "Mariana Costa Ribeiro" => {
    chief_complaint: "Dor de cabeça recorrente há 3 dias",
    subjective: "Paciente relata cefaleia recorrente há 3 dias, de leve a moderada intensidade, sem aura. Nega febre. Faz uso regular de anticoncepcional oral.",
    objective: "PA 118x76 mmHg. FC 72bpm. Exame neurológico sem alterações. Ausência de sinais de irritação meníngea.",
    assessment: "Cefaleia tensional, provável relação com jornada de trabalho e sono irregular. Sem sinais de alarme.",
    diagnosis: "Cefaleia tensional (CID-10 G44.2)",
    plan: "Orientações de higiene do sono. Retorno em 2 semanas se persistência. Emitido atestado de 1 dia.",
    blood_pressure: "118x76", heart_rate: 72, temperature: 36.6, weight_kg: 61.0, height_cm: 165.0,
  },
  "Eduardo Ferreira Lima" => {
    chief_complaint: "Tosse seca e falta de ar aos esforços",
    subjective: "Paciente refere tosse seca há 5 dias e leve falta de ar aos esforços. Nega febre. Tabagista social.",
    objective: "Ausculta pulmonar com sibilos discretos em base direita. SpO2 97%. Sem sinais de dispneia em repouso.",
    assessment: "Quadro compatível com bronquite aguda leve.",
    diagnosis: "Bronquite aguda (CID-10 J20)",
    plan: "Prescrito broncodilatador e corticoide oral. Retorno em 7 dias se não houver melhora. Orientado a suspender tabagismo.",
    blood_pressure: "124x80", heart_rate: 88, temperature: 37.1, weight_kg: 78.5, height_cm: 176.0,
  },
  "Juliana Reis" => {
    chief_complaint: "Retorno cardiológico de rotina",
    subjective: "Retorno de rotina. Nega dor torácica ou palpitações desde o ajuste da medicação há 30 dias.",
    objective: "PA 128x82 mmHg. FC 68bpm regular. ECG sem alterações agudas.",
    assessment: "Hipertensão controlada com a medicação atual.",
    diagnosis: "Hipertensão arterial (CID-10 I10)",
    plan: "Manter losartana 50mg. Retorno em 6 meses com novo ECG.",
    blood_pressure: "128x82", heart_rate: 68, temperature: 36.4, weight_kg: 69.0, height_cm: 160.0,
  },
  "Davi Ferreira" => {
    chief_complaint: "Coriza e tosse leve",
    subjective: "Mãe relata coriza e tosse leve há 2 dias, sem febre. Criança ativa e brincando normalmente.",
    objective: "Ausculta pulmonar limpa. Orofaringe sem hiperemia significativa. Peso 17,2kg, dentro da curva.",
    assessment: "Quadro viral de vias aéreas superiores, sem sinais de gravidade.",
    diagnosis: "IVAS viral (CID-10 J06.9)",
    plan: "Manter hidratação e observação. Retorno se surgir febre ou piora respiratória.",
    heart_rate: 110, temperature: 36.8, weight_kg: 17.2, height_cm: 104.0,
  },
}

rx_data = {
  "Eduardo Ferreira Lima" => {
    items: [
      { medication_name: "Salbutamol spray", dosage: "100mcg", frequency: "de 6/6h se necessário", duration: "7 dias" },
      { medication_name: "Prednisona", dosage: "20mg", frequency: "1x ao dia", duration: "5 dias" },
    ],
    notes: "Retornar caso não haja melhora em 7 dias ou piora do quadro respiratório.",
  },
  "Mariana Costa Ribeiro" => {
    items: [
      { medication_name: "Paracetamol", dosage: "750mg", frequency: "de 6/6h se dor", duration: "3 dias" },
    ],
    notes: "Evitar Dipirona — paciente alérgica.",
  },
}

appt_data.each do |data|
  patient = patients.fetch(data[:patient])
  starts_at = at(today, *data[:start])
  ends_at = at(today, *data[:finish])

  appointment = Appointment.find_or_initialize_by(patient: patient, professional: data[:prof], starts_at: starts_at)
  appointment.assign_attributes(
    organization: organization, unit: data[:prof].unit, ends_at: ends_at,
    appointment_type: data[:type], status: data[:status]
  )
  new_record = appointment.new_record?
  appointment.save!

  if new_record
    if data[:status] == "faltou"
      audit!(appointment, action: "create", actor: larissa, at: 2.weeks.ago)
      audit!(appointment, action: "update", actor: "Sistema (WhatsApp)", at: 5.days.ago,
             changes: { "status" => ["aguardando", "confirmado"] })
      audit!(appointment, action: "update", actor: larissa, at: at(today, data[:start][0], data[:start][1]),
             changes: { "status" => ["confirmado", "faltou"] })
    elsif data[:status] != "aguardando"
      audit!(appointment, action: "create", actor: larissa, at: 10.days.ago)
      audit!(appointment, action: "update", actor: "Sistema (WhatsApp)", at: 3.days.ago,
             changes: { "status" => ["aguardando", "confirmado"] })
      if %w[atendimento concluido].include?(data[:status])
        audit!(appointment, action: "update", actor: data[:prof].name, at: at(today, data[:start][0], data[:start][1]),
               changes: { "status" => ["confirmado", data[:status] == "atendimento" ? "atendimento" : "concluido"] })
      end
    else
      audit!(appointment, action: "create", actor: larissa, at: 6.days.ago)
    end
  end

  soap = soap_data[data[:patient]]
  if soap && %w[atendimento concluido].include?(data[:status]) && appointment.encounter.nil?
    encounter = appointment.build_encounter(patient: patient, professional: data[:prof])
    encounter.assign_attributes(soap)
    encounter.save!
    audit!(encounter, action: "create", actor: data[:prof].name, at: at(today, data[:start][0], data[:start][1]) + 15.minutes)

    rx = rx_data[data[:patient]]
    if rx
      issued_at = at(today, *data[:start]) + 20.minutes
      prescription = encounter.prescriptions.build(
        organization: organization, patient: patient, professional: data[:prof],
        issued_at: issued_at, notes: rx[:notes]
      )
      rx[:items].each { |item| prescription.prescription_items.build(item) }
      prescription.save!
      audit!(prescription, action: "create", actor: data[:prof].name, at: issued_at)
    end
  end
end

# ---------- A follow-up already scheduled, to showcase the retorno relationship ----------
juliana_appt = Appointment.joins(:patient).find_by(patients: { name: "Juliana Reis" }, professional: rafael)
if juliana_appt && juliana_appt.follow_ups.none?
  fu_start = juliana_appt.starts_at + 6.months
  follow_up = Appointment.create!(
    organization: organization, unit: jardins, professional: rafael, patient: patients["Juliana Reis"],
    starts_at: fu_start, ends_at: fu_start + 30.minutes, appointment_type: "Retorno", status: "aguardando",
    follow_up_of: juliana_appt
  )
  audit!(follow_up, action: "create", actor: rafael.name, at: juliana_appt.starts_at + 25.minutes)
end

# ---------- Consultas extras agendadas manualmente pela agenda (preservadas do ambiente de dev) ----------
extra_appt_data = [
  { prof: henrique, patient: "Beatriz Andrade", days_from_today: 1, start: [10, 45], finish: [11, 15], type: "Consulta" },
  { prof: beatriz, patient: "Vinícius Andrade Ramos", days_from_today: 2, start: [8, 15], finish: [8, 45], type: "Consulta" },
  { prof: henrique, patient: "Sofia Duarte", days_from_today: 2, start: [13, 45], finish: [14, 45], type: "Consulta" },
]

extra_appt_data.each do |data|
  patient = patients.fetch(data[:patient])
  day = Date.current + data[:days_from_today].days
  starts_at = at(day, *data[:start])
  ends_at = at(day, *data[:finish])

  appointment = Appointment.find_or_initialize_by(patient: patient, professional: data[:prof], starts_at: starts_at)
  new_record = appointment.new_record?
  appointment.assign_attributes(
    organization: organization, unit: data[:prof].unit, ends_at: ends_at,
    appointment_type: data[:type], status: "aguardando", created_by: admin
  )
  appointment.save!
  audit!(appointment, action: "create", actor: admin, at: Time.current) if new_record
end

puts "Seed concluído."
puts "Organização: #{organization.name}"
puts "Unidades: #{organization.units.pluck(:name).join(', ')}"
puts "Profissionais: #{Professional.count}"
puts "Pacientes: #{Patient.count}"
puts "Consultas hoje: #{Appointment.for_day(Date.current).count}"
puts "Atendimentos com prontuário: #{Encounter.count}"
puts "Receitas emitidas: #{Prescription.count}"
puts "Total de consultas (incluindo futuras): #{Appointment.count}"
puts
puts "Login (admin):       admin@amparosaude.com.br / #{PASSWORD}"
puts "Login (admin):       felipe4bfonseca@gmail.com / 12345678"
puts "Login (secretária):  larissa@amparosaude.com.br / #{PASSWORD}"
puts "Login (secretária):  renata@amparosaude.com.br / #{PASSWORD}"
puts "Login (médica):      camila@amparosaude.com.br / #{PASSWORD}"
puts "Login (médico):      rafael@amparosaude.com.br / #{PASSWORD}"
puts "Pacientes de demonstração (sem login por enquanto): #{patients.keys.join(', ')}"
