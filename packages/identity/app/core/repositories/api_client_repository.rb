module Repositories
  class ApiClientRepository
    def find_by_key(api_key)
      client = ::Identity::ApiClient.find_by(api_key: api_key, active: true)
      return nil unless client
      map_to_entity(client)
    end

    private

    def map_to_entity(client)
      Domains::Entities::ApiClientEntity.new(
        id: client.id,
        tenant_id: client.tenant_id,
        name: client.name,
        api_key: client.api_key,
        active: client.active
      )
    end
  end
end
