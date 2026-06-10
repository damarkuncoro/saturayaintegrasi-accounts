# frozen_string_literal: true

module Identity
  module Commands
    module Account
      class UpdateEmailCommand < ::Core::BaseCommand
        attribute :email, :string
        attribute :password_challenge, :string

        normalize :email, with: :email

        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
        validates :password_challenge, presence: true
      end
    end
  end
end
