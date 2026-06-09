module SatuRayaCommons
  class Engine < ::Rails::Engine
    # Tambahkan app/core ke autoload paths agar UseCases, Domains, dll bisa diakses langsung
    config.autoload_paths << File.expand_path("../../app/core", __dir__)
    
    # Pastikan engine views diprioritaskan
    config.before_initialize do |app|
      app.config.paths["app/views"].unshift(File.expand_path("../../app/views", __dir__))
    end

    config.after_initialize do
      SatuRayaCommons::Config.validate! unless Rails.env.test?
    end
  end
end
