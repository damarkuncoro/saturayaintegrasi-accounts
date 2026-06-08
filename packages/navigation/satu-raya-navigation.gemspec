Gem::Specification.new do |spec|
  spec.name        = "satu-raya-navigation"
  spec.version     = "0.1.0"
  spec.authors     = ["Satu Raya Integrasi Team"]
  spec.email       = ["support@saturaya.id"]
  spec.summary     = "Cross-application navigation and service discovery helpers"
  spec.description = "Provides URL helpers for navigating between subdomains and services in the Satu Raya ecosystem."
  spec.homepage    = "https://github.com/damarkuncoro/saturayaintegrasi-accounts"
  spec.license     = "Nonstandard"

  spec.files = Dir["{app,config,db,lib}/**/*", "README.md"]

  spec.add_dependency "rails", "~> 8.1", ">= 8.1.0"
end
