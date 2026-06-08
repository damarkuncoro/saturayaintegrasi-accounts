Gem::Specification.new do |spec|
  spec.name        = "satu-raya-ui"
  spec.version     = "0.1.0"
  spec.authors     = ["Satu Raya Integrasi Team"]
  spec.email       = ["support@saturaya.id"]
  spec.summary     = "Reusable UI primitives for Satu Raya Integrasi products"
  spec.description = "Shared UI components, view helpers, and presentation primitives for Satu Raya Integrasi applications."
  spec.homepage    = "https://github.com/damarkuncoro/saturayaintegrasi-accounts"
  spec.license     = "Nonstandard"

  spec.files = Dir["{app,config,db,lib}/**/*", "README.md"]

  spec.add_dependency "rails", "~> 8.1", ">= 8.1.0"
end
