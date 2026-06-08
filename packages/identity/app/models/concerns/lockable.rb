# frozen_string_literal: true

# Concern untuk menangani penguncian akun (account lockout) setelah beberapa kali gagal login.
# Digunakan oleh model User.
module Lockable
  extend ActiveSupport::Concern

  included do
    # Scope untuk mendapatkan record yang sedang terkunci
    scope :locked, -> { where.not(locked_at: nil) }
    # Scope untuk mendapatkan record yang tidak terkunci
    scope :unlocked, -> { where(locked_at: nil) }
  end

  # Memeriksa apakah akun sedang terkunci
  def locked?
    locked_at.present?
  end

  # Mengunci akun
  def lock!
    update!(locked_at: Time.current)
  end

  # Membuka kunci akun dan meriset jumlah kegagalan login
  def unlock!
    update!(locked_at: nil, failed_attempts: 0)
  end

  # Mencatat kegagalan login dan menambah counter
  def record_failed_attempt!
    increment!(:failed_attempts)
  end

  # Meriset counter kegagalan login tanpa membuka kunci (jika tidak sedang terkunci)
  def reset_failed_attempts!
    update!(failed_attempts: 0)
  end
end
