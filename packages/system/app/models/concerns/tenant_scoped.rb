# frozen_string_literal: true

# Concern untuk menangani scoping berdasarkan Tenant.
# Digunakan oleh hampir semua model utama yang memerlukan isolasi data per tenant.
module TenantScoped
  extend ActiveSupport::Concern

  included do
    acts_as_tenant :tenant, class_name: "System::Tenant"

    # Memastikan tenant_id selalu ada
    validates :tenant_id, presence: true

    # Scope untuk memfilter record berdasarkan tenant
    # @param tenant [System::Tenant, UUID] objek tenant atau ID tenant
    scope :for_tenant, ->(tenant) {
      tenant_id = tenant.is_a?(ActiveRecord::Base) ? tenant.id : tenant
      where(tenant_id: tenant_id)
    }
  end
end
