# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'base64'

module Services
  module System
  class CertificateAuthorityService
    # Singleton-like Root CA cache
    @root_key = nil
    @root_cert = nil

    class << self
      def root_ca
        @root_key ||= OpenSSL::PKey::RSA.new(2048)
        @root_cert ||= begin
          cert = OpenSSL::X509::Certificate.new
          cert.version = 2
          cert.serial = 1
          cert.subject = OpenSSL::X509::Name.parse("/CN=#{brand_name} Root CA/O=#{brand_name}/C=ID")
          cert.issuer = cert.subject
          cert.public_key = @root_key.public_key
          cert.not_before = Time.current - 1.day
          cert.not_after = Time.current + 10.years

          ef = OpenSSL::X509::ExtensionFactory.new
          ef.subject_certificate = cert
          ef.issuer_certificate = cert
          cert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
          cert.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
          cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
          cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))

          cert.sign(@root_key, OpenSSL::Digest.new('SHA256'))
          cert
        end
        [@root_key, @root_cert]
      end

      # Menerbitkan sertifikat X.509 baru untuk ::Identity::User
      def issue_user_certificate(user, pin)
        root_key, root_cert = root_ca

        # Generate ::Identity::User RSA Key pair
        user_key = OpenSSL::PKey::RSA.new(2048)

        # Generate ::Identity::User X.509 Certificate
        user_cert = OpenSSL::X509::Certificate.new
        user_cert.version = 2
        user_cert.serial = SecureRandom.random_number(2**32)
        user_cert.subject = OpenSSL::X509::Name.parse("/CN=#{user.full_name}/emailAddress=#{user.email}/O=#{brand_name}/C=ID")
        user_cert.issuer = root_cert.subject
        user_cert.public_key = user_key.public_key
        user_cert.not_before = Time.current - 1.hour
        user_cert.not_after = Time.current + 2.years

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = user_cert
        ef.issuer_certificate = root_cert
        user_cert.add_extension(ef.create_extension("basicConstraints", "CA:FALSE", true))
        user_cert.add_extension(ef.create_extension("keyUsage", "digitalSignature, nonRepudiation", true))
        user_cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
        user_cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))

        user_cert.sign(root_key, OpenSSL::Digest.new('SHA256'))

        # Enkripsi Private Key dengan PIN pengguna menggunakan ActiveSupport::MessageEncryptor
        salt = OpenSSL::Random.random_bytes(16)
        secret = OpenSSL::PKCS5.pbkdf2_hmac(pin, salt, 20000, 32, "sha256")
        encryptor = ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-gcm")
        encrypted_key = encryptor.encrypt_and_sign(user_key.to_pem)

        # Return data terstruktur untuk disimpan di database
        {
          certificate_pem: user_cert.to_pem,
          encrypted_private_key: encrypted_key,
          encryption_iv: Base64.strict_encode64(salt),
          serial_number: user_cert.serial.to_s,
          expires_at: user_cert.not_after
        }
      end

      # Dekripsi Private Key menggunakan PIN
      def decrypt_private_key(encrypted_private_key, salt_base64, pin)
        salt = Base64.strict_decode64(salt_base64)
        secret = OpenSSL::PKCS5.pbkdf2_hmac(pin, salt, 20000, 32, "sha256")
        encryptor = ActiveSupport::MessageEncryptor.new(secret, cipher: "aes-256-gcm")
        
        begin
          private_key_pem = encryptor.decrypt_and_verify(encrypted_private_key)
          OpenSSL::PKey::RSA.new(private_key_pem)
        rescue ActiveSupport::MessageEncryptor::InvalidMessage, OpenSSL::Cipher::CipherError
          nil
        end
      end

      private

      def brand_name
        if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
          SatuRayaIdentityClient::Identity::BrandConfig.name
        else
          "Satu Raya Integrasi"
        end
      end
    end
  end
end