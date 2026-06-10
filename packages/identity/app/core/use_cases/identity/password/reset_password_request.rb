# frozen_string_literal: true

module UseCases
  module Identity
    module Password
      class ResetPasswordRequest < ::Core::BaseUseCase
        include Normalizable

        def initialize(service: ::Identity::PasswordResetService.new)
          @service = service
        end

        # Menjalankan proses permintaan reset password
        # @param email [String] Email user yang meminta reset
        # @param tenant [System::Tenant] Tenant terkait
        # @param ip_address [String] Alamat IP request
        # @return [Core::Result]
        def perform_execute(email:, tenant:, ip_address: nil)
          command = validate_with(::Identity::Commands::Password::ResetPasswordRequestCommand, {
            email: email
          })
          # Tetap sukses meskipun validation gagal (pencegahan enumerasi email)
          
          # Gunakan service untuk logika inti
          result = @service.request_reset(email: command.email, tenant: tenant)
          
          # Selalu beri pesan yang sama demi keamanan (pencegahan enumerasi email)
          success(result.value, meta: { message: "Instruksi reset kata sandi telah dikirim jika email terdaftar." })
        rescue => e
          Rails.logger.error "[Identity::Password::ResetPasswordRequest] Error: #{e.message}"
          success(nil, meta: { message: "Instruksi reset kata sandi telah dikirim jika email terdaftar." })
        end
      end
    end
  end
end
