# frozen_string_literal: true

require "bcrypt"

module SatuRayaCommons
  module Security
    class PasswordHasher
      class << self
        def hash(password)
          BCrypt::Password.create(password).to_s
        end

        def verify?(password, password_digest)
          return false if password_digest.blank?
          BCrypt::Password.new(password_digest) == password
        rescue BCrypt::Errors::InvalidHash
          false
        end
      end
    end
  end
end
