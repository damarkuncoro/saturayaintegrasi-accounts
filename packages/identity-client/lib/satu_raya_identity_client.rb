# frozen_string_literal: true

require "satu_raya_identity_client/engine"
require "satu_raya_identity_client/identity/brand_config"
require "satu_raya_identity_client/identity/redirect_validator"

module SatuRayaIdentityClient
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :accounts_url, :client_id, :client_secret, :jwt_secret, :jwt_algorithm

    def initialize
      @accounts_url = ENV.fetch("ACCOUNTS_URL", nil)
      @client_id = ENV.fetch("IDENTITY_CLIENT_ID", nil)
      @client_secret = ENV.fetch("IDENTITY_CLIENT_SECRET", nil)
      @jwt_secret = ENV.fetch("IDENTITY_JWT_SECRET", Rails.application.secret_key_base)
      @jwt_algorithm = ENV.fetch("IDENTITY_JWT_ALGORITHM", "HS256")
    end
  end
end
