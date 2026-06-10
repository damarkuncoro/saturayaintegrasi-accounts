# frozen_string_literal: true

module UseCases
  module Identity
    module Mfa
      class PrepareTwoFactor
        attr_reader :user

        def initialize(user:)
          @user = user
        end

        # Menyiapkan rahasia TOTP jika belum ada.
        # @return [Core::Result]
        def execute
          user.prepare_2fa! unless user.otp_required_for_login?
          ::Core::Result.success(user)
        rescue StandardError => e
          Rails.logger.error "[Identity::Mfa::PrepareTwoFactor] Error: #{e.message}"
          ::Core::Result.failure("Gagal menyiapkan 2FA.")
        end
      end
    end
  end
end
