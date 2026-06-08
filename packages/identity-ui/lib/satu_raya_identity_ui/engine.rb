# frozen_string_literal: true

module SatuRayaIdentityUi
  class Engine < ::Rails::Engine
    # No isolate_namespace for global helpers

    config.to_prepare do
      ApplicationController.helper SatuRayaIdentityUi::BrandViewHelper rescue nil
    end
  end
end
