# frozen_string_literal: true

module Identity
  class BrandingsController < ApplicationController
    before_action :require_admin!

    def update
      tenant = System::Current.tenant
      
      # Extract settings params
      settings = tenant.settings.dup || {}
      settings["brand_name"] = branding_params[:brand_name]
      settings["primary_color"] = branding_params[:primary_color]
      settings["logo_url"] = branding_params[:logo_url]
      settings["privacy_url"] = branding_params[:privacy_url]
      settings["terms_url"] = branding_params[:terms_url]

      if tenant.update(settings: settings)
        redirect_to identity_account_path(anchor: "branding"), notice: "Pengaturan branding berhasil diperbarui."
      else
        redirect_to identity_account_path(anchor: "branding"), alert: "Gagal memperbarui branding: #{tenant.errors.full_messages.join(', ')}"
      end
    end

    private

    def require_admin!
      unless current_user&.admin?
        redirect_to identity_account_path, alert: "Hanya administrator yang dapat mengubah pengaturan branding."
      end
    end

    def branding_params
      params.require(:branding).permit(:brand_name, :primary_color, :logo_url, :privacy_url, :terms_url)
    end
  end
end
