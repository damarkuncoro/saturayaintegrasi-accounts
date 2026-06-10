# frozen_string_literal: true

module UseCases
  module Identity
    module Password
      class UpdatePassword < ::Core::BaseUseCase
        def initialize(service: ::Identity::PasswordResetService.new)
          @service = service
        end

        # Menjalankan proses pembaruan password
        # @param token_digest [String] Token reset yang diberikan
        # @param password [String] Password baru
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def execute(token_digest:, password:, tenant:)
          @service.reset_password(
            token_raw: token_digest, 
            new_password: password, 
            tenant: tenant
          )
        rescue => e
          Rails.logger.error "[Identity::Password::UpdatePassword] Error: #{e.message}"
          failure("Gagal memperbarui kata sandi.")
        end
      end
    end
  end
end
