# frozen_string_literal: true

module Identity
  class SsoClientsController < ApplicationController
    before_action :require_admin!
    before_action :set_sso_client, only: %i[show edit update destroy]

    def index
      @sso_clients = Identity::SsoClientConfiguration.all
    end

    def show
    end

    def new
      @sso_client = Identity::SsoClientConfiguration.new
    end

    def create
      @sso_client = Identity::SsoClientConfiguration.new(sso_client_params_without_arrays)
      
      # Parse array fields
      @sso_client.redirect_uris = parse_redirect_uris
      @sso_client.allowed_scopes = parse_allowed_scopes

      if @sso_client.save
        # Flash raw secret once since it is hashed in the database
        flash[:raw_client_secret] = @sso_client.client_secret
        redirect_to identity_sso_client_path(@sso_client), notice: "Aplikasi SSO berhasil didaftarkan."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      @sso_client.assign_attributes(sso_client_params_without_arrays)
      @sso_client.redirect_uris = parse_redirect_uris
      @sso_client.allowed_scopes = parse_allowed_scopes

      if @sso_client.save
        redirect_to identity_sso_client_path(@sso_client), notice: "Konfigurasi SSO berhasil diperbarui."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @sso_client.destroy
      redirect_to identity_sso_clients_path, notice: "Aplikasi SSO berhasil dihapus."
    end

    private

    def require_admin!
      unless current_user&.admin?
        redirect_to identity_account_path, alert: "Hanya administrator yang dapat mengelola aplikasi SSO."
      end
    end

    def set_sso_client
      @sso_client = Identity::SsoClientConfiguration.find(params[:id])
    end

    def sso_client_params_without_arrays
      params.require(:sso_client_configuration).permit(:client_name, :active)
    end

    def parse_redirect_uris
      uris_text = params[:sso_client_configuration][:redirect_uris_text]
      uris_text.to_s.split("\n").map(&:strip).reject(&:blank?)
    end

    def parse_allowed_scopes
      # Allow array values or fallback to default OIDC scopes
      scopes = params[:sso_client_configuration][:allowed_scopes]
      scopes.is_a?(Array) ? scopes.reject(&:blank?) : ["openid", "profile", "email"]
    end
  end
end
