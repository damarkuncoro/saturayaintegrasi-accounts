module System
  class Tenant < ApplicationRecord
    self.table_name = "tenants"
  has_many :users, class_name: "Identity::User", dependent: :destroy
  has_many :jobs, class_name: "Recruitment::Job", dependent: :destroy
  has_many :job_applications, class_name: "Recruitment::JobApplication", dependent: :destroy
  has_many :worker_profiles, class_name: "Profile::WorkerProfile", through: :users
  has_many :approval_requests, class_name: "Attendance::ApprovalRequest", dependent: :destroy
  has_many :shifts, class_name: "Attendance::Shift", dependent: :destroy
  has_many :devices, class_name: "Identity::Device", dependent: :destroy
  has_many :api_clients, class_name: "Identity::ApiClient", dependent: :destroy
  has_many :webhook_endpoints, class_name: "Communication::WebhookEndpoint", dependent: :destroy

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
