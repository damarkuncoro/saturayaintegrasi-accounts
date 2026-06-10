# frozen_string_literal: true

module UseCases
  module Identity
    module Oauth
      module ClientAuthHelper
        private

        def find_service_client(params, request)
          client_id = params[:client_id] || extract_client_id_from_header(request)
          ::Identity::ServiceClient.active.find_by(client_id: client_id)
        end

        def find_sso_client(params, request)
          client_id = params[:client_id] || extract_client_id_from_header(request)
          ::Identity::SsoClientConfiguration.active.find_by(client_id: client_id)
        end

        def authenticate_service_client(client, params, request)
          return false if client.nil?

          if params[:client_secret].present?
            return client.authenticate_secret(params[:client_secret])
          end

          auth_header = request.headers["Authorization"]
          if auth_header&.start_with?("Basic ")
            encoded = auth_header.sub("Basic ", "")
            decoded = Base64.decode64(encoded)
            _id, secret = decoded.split(":")
            return client.authenticate_secret(secret)
          end

          false
        end

        def authenticate_sso_client(client, params, request)
          return false if client.nil?

          if params[:client_secret].present?
            return client.authenticate_client_secret(params[:client_secret])
          end

          auth_header = request.headers["Authorization"]
          if auth_header&.start_with?("Basic ")
            encoded = auth_header.sub("Basic ", "")
            decoded = Base64.decode64(encoded)
            _id, secret = decoded.split(":")
            return client.authenticate_client_secret(secret)
          end

          false
        end

        def extract_client_id_from_header(request)
          auth_header = request.headers["Authorization"]
          return nil unless auth_header&.start_with?("Basic ")

          encoded = auth_header.sub("Basic ", "")
          decoded = Base64.decode64(encoded)
          decoded.split(":").first
        rescue StandardError
          nil
        end
      end
    end
  end
end
