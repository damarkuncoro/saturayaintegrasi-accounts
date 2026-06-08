# frozen_string_literal: true

module Identity
  class EmailVerificationService
    def initialize(user_mailer: Identity::UserMailer)
      @user_mailer = user_mailer
    end

    # Mengirim token verifikasi email
    def send_verification(user:)
      return Core::Result.failure("Email sudah terverifikasi.") if user.email_verified?

      token_raw = SecureRandom.hex(32)
      token_digest = generate_digest(token_raw)

      # Invalidate previous unused tokens
      user.email_verification_tokens.unused.update_all(used_at: Time.current)

      user.email_verification_tokens.create!(
        token_digest: token_digest,
        expires_at: 24.hours.from_now,
        tenant: user.tenant
      )

      @user_mailer.email_verification_instructions(user, token_raw).deliver_later

      Core::Result.success(user)
    end

    # Memverifikasi email dengan token
    def verify(token_raw:, tenant:)
      token_digest = generate_digest(token_raw)
      verification_token = Identity::EmailVerificationToken.unused.not_expired.find_by(
        token_digest: token_digest,
        tenant: tenant
      )

      return Core::Result.failure("Token tidak valid atau sudah kedaluwarsa.") unless verification_token

      user = verification_token.user
      
      Identity::User.transaction do
        user.update!(email_verified_at: Time.current, verified: true)
        verification_token.mark_used!
        
        # Log audit
        user.log_audit("email_verified_success", metadata: { token_id: verification_token.id })
      end

      Core::Result.success(user)
    rescue => e
      Core::Result.failure(e.message)
    end

    private

    def generate_digest(token)
      Digest::SHA256.hexdigest(token)
    end
  end
end
