# frozen_string_literal: true

module UseCases
  module Identity
    module Auth
      class LoginWithOauth < ::Core::BaseUseCase
        include Normalizable
        transactional!

        # Menjalankan proses login atau registrasi via OAuth
        # @param auth [Hash] Data dari OmniAuth (request.env["omniauth.auth"])
        # @param tenant [System::Tenant] Tenant terkait
        # @param ip_address [String] Alamat IP request
        # @param user_agent [String] User agent request
        # @return [Core::Result]
        def perform_execute(auth:, tenant:, ip_address: nil, user_agent: nil)
          uid = auth.uid
          provider = normalize_key(auth.provider)
          email = normalize_email(auth.info.email)

          user = ::Identity::User.find_or_initialize_by(uid: uid, provider: provider, tenant: tenant) do |u|
            u.email = email
            u.first_name = normalize_text(auth.info.first_name || auth.info.name.to_s.split(" ").first)
            u.last_name = normalize_text(auth.info.last_name || (auth.info.name.to_s.split(" ").last rescue nil))
            u.password = SecureRandom.hex(16)
            u.verified = true
            u.role ||= :user
          end

          if user.save
            # Catat riwayat password jika baru dibuat
            if user.previously_new_record?
              user.password_histories.create!(
                tenant: tenant,
                password_digest: user.password_digest
              )
            end

            # Buat Sesi
            session = user.sessions.create!(
              tenant: tenant,
              ip_address: ip_address,
              user_agent: user_agent,
              expires_at: 24.hours.from_now
            )

            # Catat Audit Log
            audit_log(
              action: "oauth_login_success",
              auditable: user,
              tenant: tenant,
              metadata: { provider: provider, session_id: session.id }
            )

            success(user, meta: { session: session })
          else
            failure(user.errors.full_messages.to_sentence)
          end
        rescue => e
          Rails.logger.error "[Identity::Auth::LoginWithOauth] Error: #{e.message}"
          failure("Gagal masuk menggunakan #{auth.provider.to_s.titleize}.")
        end
      end
    end
  end
end
