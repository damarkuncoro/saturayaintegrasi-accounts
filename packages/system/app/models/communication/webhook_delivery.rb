# frozen_string_literal: true

module Communication
  class WebhookDelivery < ApplicationRecord
    self.table_name = "webhook_deliveries"
    include TenantScoped

    belongs_to :webhook_endpoint, class_name: "Communication::WebhookEndpoint"

    validates :event_name, presence: true
    validates :status, presence: true

    enum :status, { pending: "pending", success: "success", failed: "failed" }, default: "pending"
  end
end
