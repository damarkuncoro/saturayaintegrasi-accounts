# frozen_string_literal: true

require "base64"

module UseCases
  module Identity
    module Oauth
      class IntrospectToken
        class Result
          attr_reader :data, :error, :status

          def initialize(data: nil, error: nil, status: :ok)
            @data = data
            @error = error
            @status = status
          end

          def success?
            @error.nil?
          end
        end

        def initialize(params:, auth_header:)
          @params = params
          @auth_header = auth_header
        end

        def call
          client = find_service_client
          if client.nil? || !authenticate_service_client(client)
            return Result.new(error: "invalid_client", status: :unauthorized)
          end

          token = @params[:token]
          if token.blank?
            return Result.new(error: "missing_token", status: :bad_request)
          end

          begin
            payload, _header = Services::Identity::JwksManager.decode_jwt(token)

            # Cek apakah token bertipe M2M (Service Client)
            service_client = ::Identity::ServiceClient.active.find_by(client_id: payload["sub"])
            if service_client
              if service_client.tenant.nil? || (service_client.tenant.active? && service_client.tenant_id.to_s == payload["tenant_id"].to_s)
                return Result.new(data: {
                  active: true,
                  client_id: service_client.client_id,
                  tenant_id: service_client.tenant_id.to_s,
                  scopes: payload["scopes"] || payload["scope"],
                  expires_at: Time.at(payload["exp"]).iso8601
                })
              else
                return Result.new(data: { active: false })
              end
            end

            # User token introspection
            user_id = payload["sub"] || payload["user_id"]
            user = ::Identity::User.find(user_id)

            if user.active? && user.tenant.active? && user.tenant_id.to_s == payload["tenant_id"].to_s
              # Fetch user permissions
              permissions = user.user_permissions.includes(:permission).map { |up| up.permission.slug }
              permissions += user.roles.includes(:permissions).flat_map { |r| r.permissions.map(&:slug) }
              permissions = permissions.uniq

              Result.new(data: {
                active: true,
                user_id: user.id.to_s,
                tenant_id: user.tenant_id.to_s,
                role: user.role,
                permissions: permissions,
                expires_at: Time.at(payload["exp"]).iso8601
              })
            else
              Result.new(data: { active: false })
            end
          rescue JWT::DecodeError, ActiveRecord::RecordNotFound
            Result.new(data: { active: false })
          end
        end

        private

        def find_service_client
          client_id = @params[:client_id] || extract_service_client_id_from_header
          ::Identity::ServiceClient.active.find_by(client_id: client_id)
        end

        def extract_service_client_id_from_header
          return nil unless @auth_header&.start_with?("Basic ")
          
          encoded = @auth_header.sub("Basic ", "")
          decoded = Base64.decode64(encoded)
          decoded.split(":").first
        rescue
          nil
        end

        def authenticate_service_client(client)
          if @params[:client_secret].present?
            return client.authenticate_secret(@params[:client_secret])
          end

          if @auth_header&.start_with?("Basic ")
            encoded = @auth_header.sub("Basic ", "")
            decoded = Base64.decode64(encoded)
            _id, secret = decoded.split(":")
            return client.authenticate_secret(secret)
          end

          false
        end
      end
    end
  end
end
