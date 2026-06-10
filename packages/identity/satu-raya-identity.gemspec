Gem::Specification.new do |spec|
  spec.name        = "satu-raya-identity"
  spec.version     = "0.1.0"
  spec.authors     = ["Satu Raya Integrasi Team"]
  spec.email       = ["support@saturaya.id"]
  spec.summary     = "Reusable identity domain package for Satu Raya Integrasi"
  spec.description = "Identity domain models, use cases, services, and integration boundaries for Satu Raya Integrasi products."
  spec.homepage    = "https://github.com/damarkuncoro/saturayaintegrasi-accounts"
  spec.license     = "Nonstandard"

  spec.files = Dir["{app,config,db,lib}/**/*", "README.md"]

  spec.add_dependency "rails", "~> 8.1", ">= 8.1.0"
  spec.add_dependency "satu-raya-commons"
  spec.add_dependency "satu-raya-system"
  spec.add_dependency "jwt", "~> 2.8"
  spec.add_dependency "rotp", "~> 6.3"
  spec.add_dependency "rqrcode", "~> 2.2"
end
