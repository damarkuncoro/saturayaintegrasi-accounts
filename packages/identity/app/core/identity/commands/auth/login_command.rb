# frozen_string_literal: true

module Identity
  module Commands
    module Auth
      class LoginCommand < ::Core::BaseCommand
        attribute :email, :string
        attribute :password, :string
        attribute :ip_address, :string
        attribute :user_agent, :string
        attribute :trusted_device_fingerprint, :string

        normalize :email, with: :email

        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
        validates :password, presence: true
      end
    end
  end
end
