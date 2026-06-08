Gem::Specification.new do |spec|
  spec.name        = "satu-raya-identity-client"
  spec.version     = "0.1.0"
  spec.authors     = ["Satu Raya Integrasi Team"]
  spec.email       = ["support@saturaya.id"]
  spec.summary     = "Client SDK for Satu Raya Accounts identity integration"
  spec.description = "OIDC/OAuth client helpers, token verification, and Rails integration utilities for apps using Satu Raya Accounts."
  spec.homepage    = "https://github.com/damarkuncoro/saturayaintegrasi-accounts"
  spec.license     = "Nonstandard"

  spec.files = Dir["{app,config,db,lib}/**/*", "README.md"]

  spec.add_dependency "rails", "~> 8.1", ">= 8.1.0"
  spec.add_dependency "jwt", "~> 2.8"
  spec.add_dependency "satu-raya-navigation"
end
