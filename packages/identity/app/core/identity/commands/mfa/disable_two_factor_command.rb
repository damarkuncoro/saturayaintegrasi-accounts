# frozen_string_literal: true

module Identity
  module Commands
    module Mfa
      class DisableTwoFactorCommand < ::Core::BaseCommand
        attribute :password_challenge, :string

        validates :password_challenge, presence: true
      end
    end
  end
end
