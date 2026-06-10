# frozen_string_literal: true

module UseCases
  module Identity
    module Password
      class UpdatePassword < ::Core::BaseUseCase
        transactional!

        def initialize(service: ::Identity::PasswordResetService.new)
          @service = service
        end

        # Menjalankan proses pembaruan password
        # @param token_digest [String] Token reset yang diberikan
        # @param password [String] Password baru
        # @param password_confirmation [String] Konfirmasi password baru
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def perform_execute(token_digest:, password:, password_confirmation:, tenant:)
          command = validate_with(::Identity::Commands::Password::UpdatePasswordCommand, {
            password: password,
            password_confirmation: password_confirmation
          })
          return failure(command.error_messages, code: :validation_error) if command.failure?

          @service.reset_password(
            token_raw: token_digest, 
            new_password: command.password, 
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
