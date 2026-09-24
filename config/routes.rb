Rails.application.routes.draw do
  root "showtimes#index"

  # FA-1: Authentifizierung
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # FA-1: Passwort vergessen
  resources :password_resets, only: [ :new, :create, :edit, :update ], param: :token

  # FA-2/FA-3/FA-4: Kunde
  resources :users, only: [ :index, :show, :edit, :update, :destroy ]
  resources :movies, only: [ :show ]
  resources :showtimes, only: [ :index, :show ] do
    # FA-Opt-3: temporaere Sitzplatzreservierung
    resources :seat_holds, only: [ :create, :destroy ]
    # FA-Opt-2: Bestaetigung und simulierter Zahlungsvorgang
    resource :checkout, only: [ :show ], controller: "checkouts"
  end
  resources :bookings, only: [ :index, :show, :create, :destroy ]

  # FA-5/FA-6 + Aktivitaetsprotokoll: Admin
  namespace :admin do
    root "movies#index"
    resources :movies, except: [ :show ]
    resources :auditoria, except: [ :show ], controller: "auditoria"
    resources :showtimes, except: [ :show ]
    resources :activity_logs, only: [ :index ]
  end
end
