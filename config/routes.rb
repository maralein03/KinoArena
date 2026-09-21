Rails.application.routes.draw do
  root "showtimes#index"

  # FA-1: Authentifizierung
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # FA-3/FA-4: Kunde
  resources :users, only: [ :index, :show, :edit, :update, :destroy ]
  resources :showtimes, only: [ :index, :show ]
  resources :bookings, only: [ :index, :show, :create, :destroy ]

  # FA-5/FA-6 + Aktivitaetsprotokoll: Admin
  namespace :admin do
    root "movies#index"
    resources :movies, except: [ :show ]
    resources :showtimes, except: [ :show ]
    resources :activity_logs, only: [ :index ]
  end
end
