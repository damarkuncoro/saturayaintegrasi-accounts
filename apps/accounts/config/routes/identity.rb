namespace :identity do
  resource :email,              only: [ :edit, :update ]
  resource :email_verification, only: [ :show, :create ]
  resource :password_reset,     only: [ :new, :edit, :create, :update ]
end
