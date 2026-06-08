module System
  class Tenant < ApplicationRecord
    self.table_name = "tenants"
    
    has_many :users, class_name: "Identity::User", dependent: :destroy
    has_many :devices, class_name: "Identity::Device", dependent: :destroy
    has_many :api_clients, class_name: "Identity::ApiClient", dependent: :destroy

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true,
              format: { with: /\A[a-z0-9-]+\z/, message: "hanya huruf kecil, angka, dan strip" }
    validates :plan, presence: true

    enum :plan, { starter: "starter", pro: "pro", enterprise: "enterprise" }

    include SoftDeletable
    include Auditable

    scope :active, -> { where(active: true) }
  end
end
