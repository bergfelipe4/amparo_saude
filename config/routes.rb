Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "painel", to: "dashboard#show", as: :dashboard
  get "agenda", to: "agenda#show", as: :agenda
  patch "agenda/:id", to: "agenda#move", as: :move_agenda_appointment

  resources :patients, only: [:index, :show, :new, :create, :update]

  get "atendimentos", to: "encounters#index", as: :encounters
  get "atendimentos/novo", to: "appointments#new", as: :new_appointment
  post "atendimentos", to: "appointments#create", as: :appointments
  get "atendimentos/:appointment_id", to: "encounters#show", as: :encounter
  patch "atendimentos/:appointment_id", to: "encounters#update"
  delete "atendimentos/:appointment_id", to: "encounters#destroy"
  get "atendimentos/:appointment_id/imprimir", to: "encounters#print", as: :print_encounter

  patch "atendimentos/:appointment_id/confirmar", to: "encounters#confirm", as: :confirm_encounter
  patch "atendimentos/:appointment_id/iniciar", to: "encounters#start", as: :start_encounter
  patch "atendimentos/:appointment_id/finalizar", to: "encounters#finish", as: :finish_encounter
  patch "atendimentos/:appointment_id/reabrir", to: "encounters#reopen", as: :reopen_encounter
  patch "atendimentos/:appointment_id/falta", to: "encounters#no_show", as: :no_show_encounter
  patch "atendimentos/:appointment_id/cancelar", to: "encounters#cancel", as: :cancel_encounter
  post "atendimentos/:appointment_id/retorno", to: "encounters#schedule_follow_up", as: :schedule_follow_up_encounter

  post "atendimentos/:appointment_id/receitas", to: "prescriptions#create", as: :prescriptions
  get "receitas/:id/imprimir", to: "prescriptions#print", as: :print_prescription

  post "atendimentos/:appointment_id/permissoes", to: "appointment_permissions#create", as: :appointment_permissions
  delete "atendimentos/:appointment_id/permissoes/:id", to: "appointment_permissions#destroy", as: :appointment_permission

  post "whatsapp/webhook", to: "whatsapp#webhook"

  namespace :whatsapp do
    resource :connection, only: [:show, :create, :destroy]
    get "connection/status", to: "connections#status", as: :connection_status
  end

  get "admin", to: "admin#show", as: :admin_overview
  namespace :admin do
    resources :users, only: [:index, :new, :create, :edit, :update]
  end

  root "dashboard#show"
end
