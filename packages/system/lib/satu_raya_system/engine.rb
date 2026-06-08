# frozen_string_literal: true

module SatuRayaSystem
  class Engine < ::Rails::Engine
    isolate_namespace SatuRayaSystem

    config.autoload_paths << File.expand_path("../../app/core", __dir__)

    initializer "satu_raya_system.identity_user_extension" do
      ActiveSupport.on_load(:identity_user) do
        has_many :digital_signatures, class_name: "System::DigitalSignature", dependent: :destroy
      end
    end
  end
end
