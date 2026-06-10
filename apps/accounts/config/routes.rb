require "satu_raya_identity_client/identity/brand_config"

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.test?
    get "mock_dashboard", to: "home#mock_dashboard", as: :mock_dashboard
  end

  scope module: :identity do
    get    "login",      to: "sessions#new",         as: :sign_in
    post   "login",      to: "sessions#create"
    get    "/auth/:provider/callback", to: "sessions#omniauth"
    get    "register",   to: "registrations#new",    as: :sign_up
    post   "register",   to: "registrations#create"
    delete "logout",     to: "sessions#destroy",     as: :sign_out

    resources :sessions, only: [ :index, :show, :destroy ]
    resource  :password, only: [ :edit, :update ]
    resource  :account,  only: [ :show, :update ] do
      post :deactivate
    end
    resource  :branding, only: :update

    resource :two_factor_settings, only: [ :show ] do
      post :enable
      post :disable
    end

    resource :two_factor_challenge, only: [ :new, :create ]

    # OIDC / OAuth2 Provider
    get  "oauth/authorize", to: "oauth#authorize"
    post "oauth/consent",   to: "oauth#consent"
    post "oauth/token",     to: "oauth#token"
    get  "oauth/userinfo",  to: "oauth#userinfo"
    post "oauth/revoke",    to: "oauth#revoke"
    post "oauth/introspect", to: "oauth#introspect"
  end

  get "dashboard",  to: "home#dashboard",       as: :identity_dashboard

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  draw :identity

  scope module: :system do
    get "/health" => "health#show"
    get "/ready" => "health#ready"
  end

  # OIDC Discovery
  get ".well-known/openid-configuration", to: "identity/discovery#openid_configuration"
  get ".well-known/jwks.json", to: "identity/discovery#jwks"

  root to: "home#index"
end
