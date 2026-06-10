# frozen_string_literal: true

module Identity
  module Commands
    module Password
      class ResetPasswordRequestCommand < ::Core::BaseCommand
        attribute :email, :string

        normalize :email, with: :email

        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
      end
    end
  end
end
