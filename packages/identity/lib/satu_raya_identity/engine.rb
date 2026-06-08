# frozen_string_literal: true

module SatuRayaIdentity
  class Engine < ::Rails::Engine
    isolate_namespace SatuRayaIdentity

    # Tambahkan app/core ke autoload paths agar UseCases, Domains, dll bisa diakses langsung
    config.autoload_paths << File.expand_path("../../app/core", __dir__)
  end
end
