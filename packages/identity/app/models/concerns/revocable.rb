# frozen_string_literal: true

# Concern untuk menangani pencabutan (revocation) akses atau persetujuan.
# Digunakan oleh model seperti Session, TrustedDevice, dan UserConsent.
module Revocable
  extend ActiveSupport::Concern

  included do
    # Relasi ke user yang melakukan pencabutan
    belongs_to :revoked_by, class_name: "Identity::User", optional: true

    # Scope untuk mendapatkan record yang masih aktif (belum dicabut)
    scope :active, -> { where(revoked_at: nil) }
    # Scope untuk mendapatkan record yang sudah dicabut
    scope :revoked, -> { where.not(revoked_at: nil) }
  end

  # Mencabut akses/persetujuan
  # @param by [User] user yang melakukan pencabutan
  # @param reason [String] alasan pencabutan
  def revoke!(by: nil, reason: nil)
    update!(
      revoked_at: Time.current,
      revoked_by: by,
      revocation_reason: reason
    )
  end

  # Memeriksa apakah sudah dicabut
  def revoked?
    revoked_at.present?
  end
end
