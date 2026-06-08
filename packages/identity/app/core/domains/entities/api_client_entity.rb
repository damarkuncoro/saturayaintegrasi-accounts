module Domains
  module Entities
    class ApiClientEntity
      attr_reader :id, :tenant_id, :name, :api_key, :active, :permissions

      def initialize(id:, tenant_id:, name:, api_key:, active:, permissions: {})
        @id = id
        @tenant_id = tenant_id
        @name = name
        @api_key = api_key
        @active = active
        @permissions = permissions
      end
    end
  end
end
