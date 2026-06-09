# frozen_string_literal: true

module Communication
  class WebhookEndpoint < ApplicationRecord
    self.table_name = "webhook_endpoints"
    include TenantScoped

    has_many :webhook_deliveries, class_name: "Communication::WebhookDelivery", dependent: :destroy

    validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
    validates :secret, presence: true
    validates :events, presence: true

    before_validation :generate_secret, on: :create

    private

    def generate_secret
      self.secret ||= SecureRandom.hex(24)
    end
  end
end
