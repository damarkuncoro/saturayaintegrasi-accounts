module Identity
  class User < ApplicationRecord
    self.table_name = "users"
    has_secure_password

    generates_token_for :email_verification, expires_in: 2.days do
      email
    end

    generates_token_for :password_reset, expires_in: 20.minutes do
      password_salt.last(10)
    end

    # Generate JWT for API authentication
    def generate_jwt_token(expires_in: 24.hours)
      payload = { user_id: id, tenant_id: tenant_id }
      SatuRayaCommons::Security::JwtCodec.encode(payload, Rails.application.secret_key_base, expires_in)
    end

    # Decode JWT and return user if valid
    def self.decode_jwt_token(token)
      decoded = SatuRayaCommons::Security::JwtCodec.decode(token, Rails.application.secret_key_base)
      return nil unless decoded
      find_by(id: decoded[:user_id])
    end

    def self.generate_otp_secret
      ROTP::Base32.random
    end

    include TenantScoped
    include Lockable
    include Normalizable
    include SoftDeletable
    include Auditable

    # Transparent Active Record Encryption for sensitive PII data
    encrypts :otp_secret
    encrypts :phone
    encrypts :first_name, :last_name

    has_many :sessions, class_name: "Identity::Session", dependent: :destroy
    has_many :user_permissions, class_name: "Identity::UserPermission", dependent: :destroy
    has_many :user_roles, class_name: "Identity::UserRole", dependent: :destroy
    has_many :roles, through: :user_roles, class_name: "Identity::Role"

    def can?(action, resource_type)
      user_permissions.can?(self, action, resource_type)
    end

    def otp_qr_code
      totp = ROTP::TOTP.new(otp_secret, issuer: SatuRayaCommons::Config.brand_name)
      provisioning_uri = totp.provisioning_uri(email)
      RQRCode::QRCode.new(provisioning_uri).as_svg(
        offset: 0,
        color: "000",
        shape_rendering: "crispEdges",
        module_size: 6,
        standalone: true
      )
    end

    def verify_otp(code)
      return false if otp_secret.blank?
      totp = ROTP::TOTP.new(otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name)
      totp.verify(code, drift_behind: 30)
    end

    def enable_2fa!
      self.otp_secret = ROTP::Base32.random
      self.otp_required_for_login = true
      save!
    end

    def prepare_2fa!
      return if otp_secret.present?
      update!(otp_secret: ROTP::Base32.random, otp_required_for_login: false)
    end

    def confirm_2fa!(code)
      return false unless verify_otp(code)
      update!(otp_required_for_login: true)
    end

    def disable_2fa!
      self.otp_secret = nil
      self.otp_required_for_login = false
      mfa_backup_codes.destroy_all
      save!
    end

    def generate_mfa_backup_codes!
      mfa_backup_codes.destroy_all
      
      codes = []
      8.times do
        code = SecureRandom.hex(4) # 8 characters
        codes << code
        mfa_backup_codes.create!(
          tenant: tenant,
          code_digest: SatuRayaCommons::Security::PasswordHasher.hash(code)
        )
      end
      codes
    end

    def verify_mfa_backup_code(code)
      return false if code.blank?
      
      mfa_backup_codes.unused.find_each do |backup_code|
        if SatuRayaCommons::Security::PasswordHasher.verify?(code, backup_code.code_digest)
          backup_code.mark_used!
          return true
        end
      end
      false
    end

    # MFA & Security Associations
    has_many :user_passkeys, class_name: "Identity::UserPasskey", dependent: :destroy
    has_many :user_consents, class_name: "Identity::UserConsent", dependent: :destroy
    has_many :trusted_devices, class_name: "Identity::TrustedDevice", dependent: :destroy
    has_many :mfa_backup_codes, class_name: "Identity::MfaBackupCode", dependent: :destroy
    has_many :password_histories, class_name: "Identity::PasswordHistory", dependent: :destroy
    has_many :email_verification_tokens, class_name: "Identity::EmailVerificationToken", dependent: :destroy
    has_many :password_reset_tokens, class_name: "Identity::PasswordResetToken", dependent: :destroy

    enum :role, { user: 0, admin: 1, support: 2 }, default: :user

    scope :active, -> { where(active: true).where(disabled_at: nil).where(deleted_at: nil) }
    scope :admins, -> { where(role: :admin) }

    before_validation :generate_username, on: :create
    before_validation :normalize_identity_fields
    before_update :reset_verification_if_email_changed

    validates :email,      presence: true, uniqueness: { scope: :tenant_id },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :username,   presence: true, uniqueness: { scope: :tenant_id },
                            format: { with: /\A[a-z0-9_]+\z/ },
                            length: { minimum: 3, maximum: 30 }
    validates :first_name, presence: true
    validates :password,   length: { minimum: 12 }, if: -> { password.present? }
    validate :password_not_in_history, if: :password_digest_changed?

    def full_name
      "#{first_name} #{last_name}".strip
    end

    def active?
      active && !disabled? && !discarded?
    end

    def disabled?
      disabled_at.present?
    end

    def email_verified?
      email_verified_at.present? || verified?
    end

    def authenticated_password?(password)
      authenticate(password).present?
    end

    private

    def password_not_in_history
      return unless password.present?

      # Cek riwayat password (kecuali untuk pembuatan akun pertama kali)
      if password_histories.any? { |ph| SatuRayaCommons::Security::PasswordHasher.verify?(password, ph.password_digest) }
        errors.add(:password, "pernah digunakan sebelumnya. Silakan pilih kata sandi lain.")
      end
    end

    def generate_username
      return if username.present? || email.blank?
      
      base = email.split("@").first.to_s.gsub(/[^a-z0-9_]/, "").downcase
      self.username = base
      
      # Ensure uniqueness
      counter = 1
      while Identity::User.unscoped.exists?(tenant_id: tenant_id, username: self.username)
        self.username = "#{base}#{counter}"
        counter += 1
      end
    end

    def reset_verification_if_email_changed
      return unless email_changed?
      
      self.verified = false
    end

    # Menstandarisasi field identitas untuk konsistensi data
    def normalize_identity_fields
      self.email = normalize_email(email)
      self.unconfirmed_email = normalize_email(unconfirmed_email)
      self.username = normalize_key(username.to_s.gsub(/[^a-z0-9_]/, "")) if username.present?
      self.provider = normalize_key(provider)
      self.uid = normalize_text(uid)
      self.phone = normalize_phone(phone) || ""
      self.first_name = normalize_text(first_name)
      self.last_name = normalize_text(last_name) || ""
    end

    # Memberikan hook bagi package lain untuk melakukan kustomisasi pada model User
    # tanpa harus memodifikasi file ini secara langsung.
    ActiveSupport.run_load_hooks(:identity_user, self)
  end
end
