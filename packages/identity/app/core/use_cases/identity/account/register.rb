# frozen_string_literal: true

module UseCases
  module Identity
    module Account
      class Register < ::Core::BaseUseCase
        include Normalizable
        transactional!

        def initialize(
          verification_service: ::Identity::EmailVerificationService.new,
          sync_service: SatuRayaIdentity.user_sync_publisher
        )
          @verification_service = verification_service
          @sync_service = sync_service
        end

        # Menjalankan proses registrasi
        # @param params [Hash] Data user (email, password, name, dll)
        # @param tenant [System::Tenant] Tenant tempat user mendaftar
        # @return [Core::Result]
        def perform_execute(params:, tenant:)
          params[:email] = normalize_email(params[:email]) if params[:email]
          params[:first_name] = normalize_text(params[:first_name]) if params[:first_name]
          params[:last_name] = normalize_text(params[:last_name]) if params[:last_name]
          params[:phone] = normalize_phone(params[:phone]) if params[:phone]

          user = tenant.users.new(params)
          
          # Set default role jika tidak diberikan
          user.role ||= :user

          if user.save
            # 1. Catat riwayat password
            user.password_histories.create!(
              tenant: tenant,
              password_digest: user.password_digest
            )

            # 2. Kirim Email Verifikasi via Service
            @verification_service.send_verification(user: user)

            # 3. Sinkronisasi Data User ke service lain
            @sync_service.execute(action: "created", user: user)

            # 4. Catat Audit Log
            audit_log(
              action: "user_registered", 
              auditable: user, 
              tenant: tenant,
              metadata: { role: user.role }
            )

            success(user)
          else
            failure(user.errors.full_messages.to_sentence, code: :validation_error)
          end
        rescue => e
          Rails.logger.error "[Identity::Account::Register] Error: #{e.message}"
          failure("Gagal mendaftarkan pengguna baru.", code: :system_error)
        end
      end
    end
  end
end
