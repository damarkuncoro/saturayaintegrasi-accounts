puts "Loading user_repository.rb"
module Repositories
  module Identity
  class UserRepository < ::Core::BaseRepository
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

    protected

    def model_class
      ::Identity::User
    end

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