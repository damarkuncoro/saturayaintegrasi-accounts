require "net/http"

module SatuRayaCommons
  class InternalApiClient
    def self.post(service_url_key, path, payload, headers = {})
      new(service_url_key).post(path, payload, headers)
    end

    def self.post_to_url(url, path, payload, headers = {})
      client = new(nil)
      client.instance_variable_set(:@base_url, url)
      client.post(path, payload, headers)
    end

    def initialize(service_url_key)
      @base_url = ENV.fetch(service_url_key) if service_url_key
      @secret = ENV.fetch("HMAC_SECRET")
    end

    def post(path, payload, headers = {})
      uri = URI.join(@base_url, path)
      payload_json = payload.to_json
      
      # Generate HMAC Signature
      signature = SatuRayaCommons::Security::HmacSigner.sign(payload_json, @secret)

      request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
      request["X-Internal-Signature"] = signature
      request["X-Internal-Payload"] = payload_json # Optional, based on your auth strategy
      
      headers.each { |k, v| request[k] = v }
      request.body = payload_json

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    rescue => e
      Rails.logger.error("[InternalApiClient] Failed to call #{uri}: #{e.message}")
      raise e
    end
  end
end
