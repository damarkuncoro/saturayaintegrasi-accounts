# frozen_string_literal: true

module UseCases
  module Identity
    module Account
      class VerifyEmail < ::Core::BaseUseCase
        transactional!

        def initialize(
          service: ::Identity::EmailVerificationService.new,
          sync_service: SatuRayaIdentity.user_sync_publisher
        )
          @service = service
          @sync_service = sync_service
        end

        # Menjalankan proses verifikasi email
        # @param token_digest [String] Token verifikasi yang diberikan
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def perform_execute(token_digest:, tenant:)
          result = @service.verify(token_raw: token_digest, tenant: tenant)
          
          if result.success?
            user = result.value
            # Sinkronisasi Data User (status verified berubah)
            @sync_service.execute(action: "updated", user: user)

            # Catat Audit Log
            audit_log(
              action: "email_verified",
              auditable: user,
              tenant: tenant
            )
          end

          result
        rescue => e
          Rails.logger.error "[Identity::Account::VerifyEmail] Error: #{e.message}"
          failure("Gagal memverifikasi email.")
        end
      end
    end
  end
end
