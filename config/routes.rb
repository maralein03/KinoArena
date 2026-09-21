Rails.application.routes.draw do
  get "showtimes/index"
  get "showtimes/show"
  root "showtimes#index"

  # Authentifizierung
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :users, only: [:index, :show, :edit, :update, :destroy]
  resources :showtimes, only: [:index, :show]
  resources :bookings, only: [:index, :show, :create]
end