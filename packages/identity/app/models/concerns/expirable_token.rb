# frozen_string_literal: true

# Concern untuk menangani token yang memiliki masa berlaku (expiration) dan status penggunaan (usage).
# Digunakan oleh model seperti EmailVerificationToken, PasswordResetToken, dll.
module ExpirableToken
  extend ActiveSupport::Concern

  included do
    # Scope untuk mendapatkan token yang belum digunakan
    scope :unused, -> { where(used_at: nil) }
    # Scope untuk mendapatkan token yang sudah digunakan
    scope :used, -> { where.not(used_at: nil) }
    # Scope untuk mendapatkan token yang belum kedaluwarsa
    scope :not_expired, -> { where("expires_at > ?", Time.current) }
  end

  # Memeriksa apakah token sudah kedaluwarsa
  def expired?
    expires_at <= Time.current
  end

  # Memeriksa apakah token sudah digunakan
  def used?
    used_at.present?
  end

  # Memeriksa apakah token masih bisa digunakan (belum digunakan dan belum kedaluwarsa)
  def usable?
    !used? && !expired?
  end

  # Menandai token sebagai sudah digunakan
  def mark_used!
    update!(used_at: Time.current)
  end
end
