# frozen_string_literal: true

module Identity
  class PasswordResetService
    def initialize(user_mailer: Identity::UserMailer)
      @user_mailer = user_mailer
    end

    # Mengirim instruksi reset password ke email user
    def request_reset(email:, tenant:)
      user = Identity::User.active.find_by(email: email, tenant: tenant)
      
      # Tetap return success meskipun user tidak ditemukan untuk mencegah email enumeration
      return Core::Result.success(nil) unless user

      token_raw = SecureRandom.hex(32)
      token_digest = generate_digest(token_raw)

      # Invalidate previous unused tokens
      user.password_reset_tokens.unused.update_all(used_at: Time.current)

      user.password_reset_tokens.create!(
        token_digest: token_digest,
        expires_at: 2.hours.from_now,
        tenant: tenant
      )

      @user_mailer.password_reset_instructions(user, token_raw).deliver_later

      Core::Result.success(user)
    end

    # Mereset password dengan token yang valid
    def reset_password(token_raw:, new_password:, tenant:)
      token_digest = generate_digest(token_raw)
      reset_token = Identity::PasswordResetToken.unused.not_expired.find_by(
        token_digest: token_digest,
        tenant: tenant
      )

      return Core::Result.failure("Token tidak valid atau sudah kedaluwarsa.") unless reset_token

      user = reset_token.user
      
      Identity::User.transaction do
        user.update!(password: new_password)
        reset_token.mark_used!
        
        # Log audit
        user.log_audit("password_reset_success", metadata: { token_id: reset_token.id })
      end

      Core::Result.success(user)
    rescue ActiveRecord::RecordInvalid => e
      Core::Result.failure(e.record.errors.full_messages.join(", "))
    rescue => e
      Core::Result.failure(e.message)
    end

    private

    def generate_digest(token)
      Digest::SHA256.hexdigest(token)
    end
  end
end
