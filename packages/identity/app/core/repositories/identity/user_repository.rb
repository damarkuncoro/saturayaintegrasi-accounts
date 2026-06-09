puts "Loading user_repository.rb"
module Repositories
  module Identity
  class UserRepository
    include Normalizable

    def find(id)
      user = ::Identity::User.find_by(id: id)
      return nil unless user
      to_entity(user)
    end

    def find_by_email(email, tenant:)
      user = tenant.users.find_by(email: normalize_email(email))
      return nil unless user
      to_entity(user)
    end

    def find_by_email_global(email)
      user = ::Identity::User.unscoped.find_by(email: normalize_email(email))
      return nil unless user
      to_entity(user)
    end

    def create(attributes)
      user = ::Identity::User.create!(attributes)
      to_entity(user)
    end

    def update(id, attributes)
      user = ::Identity::User.find(id)
      user.update!(attributes)
      to_entity(user)
    end

    private

    def to_entity(user)
      ::Domains::Entities::Identity::UserEntity.new(
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        tenant_id: user.tenant_id,
        active: user.active,
        disabled_at: user.disabled_at,
        password_digest: user.password_digest
      )
    end
  end
end
end