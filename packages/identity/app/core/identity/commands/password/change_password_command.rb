# frozen_string_literal: true

module Identity
  module Commands
    module Password
      class ChangePasswordCommand < ::Core::BaseCommand
        attribute :password, :string
        attribute :password_confirmation, :string
        attribute :password_challenge, :string
        attribute :revoke_others, :boolean, default: false

        validates :password, presence: true, length: { minimum: 8 }
        validates :password_challenge, presence: true

        validate :passwords_match

        private

        def passwords_match
          if password != password_confirmation
            errors.add(:password_confirmation, "tidak cocok dengan kata sandi baru")
          end
        end
      end
    end
  end
end
