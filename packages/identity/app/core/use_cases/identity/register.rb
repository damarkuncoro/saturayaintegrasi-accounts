# frozen_string_literal: true

module UseCases
  module Identity
    class Register
      include Normalizable

    def initialize(
      verification_service: ::Identity::EmailVerificationService.new,
      audit_logger: Services::System::AuditLogger, 
      sync_service: UseCases::PublishUserSyncEvent.new
    )
      @verification_service = verification_service
      @audit_logger = audit_logger
      @sync_service = sync_service
    end

    # Menjalankan proses registrasi
    # @param params [Hash] Data user (email, password, name, dll)
    # @param tenant [System::Tenant] Tenant tempat user mendaftar
    # @return [Core::Result]
    def call(params:, tenant:)
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
        @sync_service.call(action: "created", user: user)

        # 4. Catat Audit Log
        @audit_logger.log(
          action: "user_registered", 
          auditable: user, 
          tenant: tenant,
          metadata: { role: user.role }
        )

        Core::Result.success(user)
      else
        Core::Result.failure(user.errors.full_messages.to_sentence)
      end
    rescue => e
      Rails.logger.error "[Identity::Register] Error: #{e.message}"
      Core::Result.failure("Gagal mendaftarkan pengguna baru.")
    end

    private
  end
end
end
