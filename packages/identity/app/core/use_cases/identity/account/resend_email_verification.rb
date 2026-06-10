# frozen_string_literal: true

module UseCases
  module Identity
    module Account
      class ResendEmailVerification < ::Core::BaseUseCase
        def initialize(service: ::Identity::EmailVerificationService.new)
          @service = service
        end

        # Menjalankan proses pengiriman ulang email verifikasi
        # @param user [Identity::User] User yang meminta verifikasi ulang
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def execute(user:, tenant:)
          @service.send_verification(user: user)
          
          # Catat Audit Log
          audit_log(
            action: "email_verification_resent",
            auditable: user,
            tenant: tenant
          )

          success(user)
        rescue => e
          Rails.logger.error "[Identity::Account::ResendEmailVerification] Error: #{e.message}"
          failure("Gagal mengirim ulang email verifikasi.")
        end
      end
    end
  end
end
