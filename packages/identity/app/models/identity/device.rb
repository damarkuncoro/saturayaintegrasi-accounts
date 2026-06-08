module Identity
  class Device < ApplicationRecord
    self.table_name = "devices"
  acts_as_tenant :tenant, class_name: "System::Tenant"

  has_many :attendances, class_name: "Attendance::Attendance", as: :source_device

  validates :name, presence: true
  validates :serial_number, presence: true, uniqueness: { scope: :tenant_id }
  validates :device_type, presence: true

  enum :status, {
    offline: "offline",
    online: "online",
    maintenance: "maintenance"
  }, default: "offline"

  def heartbeat!
    update!(last_heartbeat_at: Time.current, status: :online)
  end
end
end
