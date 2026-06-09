module Domains
  module Entities
    module Identity
    class UserEntity
      attr_reader :id, :email, :first_name, :last_name, :role, :tenant_id, :active, :disabled_at, :password_digest

      def initialize(id:, email:, first_name:, last_name:, role:, tenant_id:, active: true, disabled_at: nil, password_digest: nil)
        @id = id
        @email = email
        @first_name = first_name
        @last_name = last_name
        @role = role
        @tenant_id = tenant_id
        @active = active
        @disabled_at = disabled_at
        @password_digest = password_digest
      end

      def active?
        !!@active
      end

      def disabled?
        @disabled_at.present?
      end

      def authenticate(password)
        return false if @password_digest.blank?
        BCrypt::Password.new(@password_digest) == password
      rescue BCrypt::Errors::InvalidHash
        false
      end

      def full_name
        "#{first_name} #{last_name}".strip
      end

      def to_h
        {
          id: id,
          email: email,
          first_name: first_name,
          last_name: last_name,
          role: role,
          tenant_id: tenant_id,
          active: active,
          disabled_at: disabled_at
        }
      end
    end
  end
end

end