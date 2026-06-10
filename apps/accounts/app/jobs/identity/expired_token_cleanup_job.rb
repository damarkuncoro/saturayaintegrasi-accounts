# frozen_string_literal: true

module Identity
  class ExpiredTokenCleanupJob < ApplicationJob
    queue_as :default

    # Purge expired email verification and password reset tokens across all tenants
    def perform
      ActsAsTenant.without_tenant do
        expired_emails = Identity::EmailVerificationToken.where("expires_at <= ?", Time.current).delete_all
        expired_passwords = Identity::PasswordResetToken.where("expires_at <= ?", Time.current).delete_all

        Rails.logger.info "[Identity::ExpiredTokenCleanupJob] Purged #{expired_emails} expired email verification tokens and #{expired_passwords} expired password reset tokens."
      end
    end
  end
end
