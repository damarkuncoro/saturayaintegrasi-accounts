# frozen_string_literal: true

module SatuRayaIdentityUI
  class Engine < ::Rails::Engine
    # No isolate_namespace for global helpers

    config.to_prepare do
      ApplicationController.helper SatuRayaIdentityUI::BrandViewHelper rescue nil
    end
  end
end
