module Domains
  module Entities
    module Identity
    class UserEntity
      attr_reader :id, :email, :first_name, :last_name, :role, :tenant_id

      def initialize(id:, email:, first_name:, last_name:, role:, tenant_id:)
        @id = id
        @email = email
        @first_name = first_name
        @last_name = last_name
        @role = role
        @tenant_id = tenant_id
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
          tenant_id: tenant_id
        }
      end
    end
  end
end

end