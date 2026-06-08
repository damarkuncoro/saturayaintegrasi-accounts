module System
  class ApplicationLog < ApplicationRecord
    self.table_name = "application_logs"
  belongs_to :job_application, class_name: "Recruitment::JobApplication"
  acts_as_tenant :tenant, class_name: "System::Tenant"

  validates :event_type, presence: true
  validates :message, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
end
