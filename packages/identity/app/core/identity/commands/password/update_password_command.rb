# frozen_string_literal: true

module Identity
  module Commands
    module Password
      class UpdatePasswordCommand < ::Core::BaseCommand
        attribute :password, :string
        attribute :password_confirmation, :string

        validates :password, presence: true, length: { minimum: 8 }

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
