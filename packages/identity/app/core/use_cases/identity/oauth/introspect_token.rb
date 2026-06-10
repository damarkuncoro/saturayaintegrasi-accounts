# frozen_string_literal: true

module UseCases
  module Identity
    module Oauth
      class IntrospectToken < ::Core::BaseUseCase
        include ClientAuthHelper

        attr_reader :params, :request

        def initialize(params:, request:)
          @params = params
          @request = request
        end

        # Mengeksekusi proses introspeksi token.
        # @return [Core::Result]
        def execute
          client = find_service_client(params, request)
          if client.nil? || !authenticate_service_client(client, params, request)
            return failure("invalid_client", meta: { status: :unauthorized })
          end

          token = params[:token]
          if token.blank?
            return failure("missing_token", meta: { status: :bad_request })
          end

          begin
            payload, _header = jwks_manager.decode_jwt(token)

            # Cek apakah token bertipe M2M (Service Client)
            service_client = ::Identity::ServiceClient.active.find_by(client_id: payload["sub"])
            if service_client
              if service_client.tenant.nil? || (service_client.tenant.active? && service_client.tenant_id.to_s == payload["tenant_id"].to_s)
                return success({
                  active: true,
                  client_id: service_client.client_id,
                  tenant_id: service_client.tenant_id.to_s,
                  scopes: payload["scopes"] || payload["scope"],
                  expires_at: Time.at(payload["exp"]).iso8601
                }, meta: { status: :ok })
              else
                return success({ active: false }, meta: { status: :ok })
              end
            end

            user_id = payload["sub"] || payload["user_id"]
            user = ::Identity::User.find(user_id)

            # Pastikan user aktif, tenant aktif, dan sesuai dengan tenant di token
            if user.active? && user.tenant.active? && user.tenant_id.to_s == payload["tenant_id"].to_s
              # Ambil perizinan user
              permissions = user.user_permissions.includes(:permission).map { |up| up.permission.slug }
              permissions += user.roles.includes(:permissions).flat_map { |r| r.permissions.map(&:slug) }
              permissions = permissions.uniq

              success({
                active: true,
                user_id: user.id.to_s,
                tenant_id: user.tenant_id.to_s,
                role: user.role,
                permissions: permissions,
                expires_at: Time.at(payload["exp"]).iso8601
              }, meta: { status: :ok })
            else
              success({ active: false }, meta: { status: :ok })
            end
          rescue JWT::DecodeError, ActiveRecord::RecordNotFound
            success({ active: false }, meta: { status: :ok })
          end
        end

        private

        def jwks_manager
          ::Services::Identity::JwksManager
        end
      end
    end
  end
end
