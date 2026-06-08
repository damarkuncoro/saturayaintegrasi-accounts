Gem::Specification.new do |spec|
  spec.name        = "satu-raya-system"
  spec.version     = "0.1.0"
  spec.authors     = ["Satu Raya Integrasi Team"]
  spec.email       = ["support@saturaya.id"]
  spec.summary     = "System infrastructure for Satu Raya Integrasi (Multi-tenancy, Auditing)"
  spec.description = "Core system models and services including Tenant management and Audit Logs."
  spec.homepage    = "https://github.com/damarkuncoro/saturayaintegrasi-accounts"
  spec.license     = "Nonstandard"

  spec.files = Dir["{app,config,db,lib}/**/*", "README.md"]

  spec.add_dependency "rails", "~> 8.1", ">= 8.1.0"
  spec.add_dependency "acts_as_tenant", "~> 1.0", ">= 1.0.1"
end
