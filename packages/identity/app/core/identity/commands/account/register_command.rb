# frozen_string_literal: true

module Identity
  module Commands
    module Account
      class RegisterCommand < ::Core::BaseCommand
        attribute :email, :string
        attribute :password, :string
        attribute :password_confirmation, :string
        attribute :first_name, :string
        attribute :last_name, :string
        attribute :phone, :string

        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
        validates :password, presence: true, length: { minimum: 8 }
        validates :first_name, presence: true
        validates :last_name, presence: true

        validate :passwords_match

        private

        def passwords_match
          if password != password_confirmation
            errors.add(:password_confirmation, "tidak cocok dengan kata sandi")
          end
        end
      end
    end
  end
end
