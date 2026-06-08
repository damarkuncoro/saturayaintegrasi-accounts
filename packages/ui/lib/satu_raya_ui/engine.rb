# frozen_string_literal: true

module SatuRayaUi
  class Engine < ::Rails::Engine
    isolate_namespace SatuRayaUi

    # Pastikan engine views diprioritaskan
    config.before_initialize do |app|
      app.config.paths["app/views"].unshift(File.expand_path("../../app/views", __dir__))
    end
  end
end
