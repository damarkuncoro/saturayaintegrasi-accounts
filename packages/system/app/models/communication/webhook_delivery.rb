# frozen_string_literal: true

module Communication
  class WebhookDelivery < ApplicationRecord
    self.table_name = "webhook_deliveries"
    include TenantScoped

    belongs_to :webhook_endpoint, class_name: "Communication::WebhookEndpoint"

    validates :event_name, presence: true
    validates :status, presence: true
    validate :tenant_must_match_webhook_endpoint

    before_validation do
      self.tenant ||= webhook_endpoint&.tenant if has_attribute?(:tenant_id)
    end

    enum :status, { pending: "pending", success: "success", failed: "failed" }, default: "pending"

    private

    def tenant_must_match_webhook_endpoint
      return if tenant_id.blank? || webhook_endpoint.blank?

      if webhook_endpoint.tenant_id != tenant_id
        errors.add(:webhook_endpoint_id, "must belong to the same tenant")
      end
    end
  end
end
