# frozen_string_literal: true

require "net/http"

module Core
  class BaseService
    # Kelas dasar untuk komunikasi inter-service.
    # Menggunakan HMAC untuk autentikasi antar-service internal.

    attr_reader :base_url, :secret_key

    def initialize(base_url: nil, secret_key: nil)
      @base_url = base_url
      @secret_key = secret_key || ENV.fetch("HMAC_SECRET", nil)
    end

    def post(path, payload = {}, headers = {})
      request(:post, path, payload, headers)
    end

    def get(path, params = {}, headers = {})
      request(:get, path, params, headers)
    end

    protected

    def request(method, path, data = {}, headers = {})
      uri = build_uri(path, method == :get ? data : {})
      
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      
      req_class = "Net::HTTP::#{method.to_s.capitalize}".constantize
      request = req_class.new(uri)
      
      # Setup headers
      default_headers.each { |k, v| request[k] = v }
      headers.each { |k, v| request[k] = v }
      
      if method != :get
        body = data.to_json
        request.body = body
        request["X-Internal-Signature"] = sign_payload(body) if secret_key
      end

      response = http.request(request)
      handle_response(response)
    rescue => e
      Rails.logger.error "[#{self.class}] Request failed: #{e.message}"
      ::Core::Result.failure("Gagal menghubungi layanan eksternal.", code: :service_unavailable)
    end

    private

    def build_uri(path, params)
      uri = URI.join(base_url, path)
      uri.query = URI.encode_www_form(params) if params.any?
      uri
    end

    def default_headers
      {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "X-Request-Id" => RequestStore.store[:request_id] || SecureRandom.uuid
      }
    end

    def sign_payload(payload)
      SatuRayaCommons::Security::HmacSigner.sign(payload, secret_key)
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        body = JSON.parse(response.body) rescue {}
        ::Core::Result.success(body)
      else
        error_msg = JSON.parse(response.body)["error"] rescue "Unknown error"
        ::Core::Result.failure(error_msg, code: "http_#{response.code}".to_sym)
      end
    end
  end
end
