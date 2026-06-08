module Identity
  class UserPasskey < ApplicationRecord
    self.table_name = "user_passkeys"
    include Normalizable

    acts_as_tenant :tenant, class_name: "System::Tenant"
    belongs_to :user, class_name: "Identity::User"

    validates :external_id, presence: true, uniqueness: { scope: :tenant_id }
    validates :public_key, presence: true
    validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :nickname, length: { maximum: 100 }, allow_blank: true

    before_validation :set_tenant_from_user, on: :create
    before_validation :normalize_fields

    private

    def normalize_fields
      self.nickname = normalize_text(nickname)
      self.external_id = normalize_key(external_id)
    end

    def set_tenant_from_user
      self.tenant ||= user&.tenant
    end
  end
end
