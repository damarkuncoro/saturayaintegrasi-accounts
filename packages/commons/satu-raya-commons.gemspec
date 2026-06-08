Gem::Specification.new do |spec|
  spec.name        = "satu-raya-commons"
  spec.version     = "1.0.0"
  spec.authors     = ["Satu Raya Integrasi Team"]
  spec.email       = ["support@saturaya.id"]
  spec.summary     = "Shared Core DDD Layers for Satu Raya Integrasi monorepo"
  spec.description = "Shared Entities, Value Objects, Repositories, Services, and Use Cases for Satu Raya Integrasi."
  spec.homepage    = "https://github.com/damarkuncoro/saturayaintegrasi-accounts"
  spec.license     = "Nonstandard"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 8.1", ">= 8.1.0"
  spec.add_dependency "jwt", "~> 2.8"
  spec.add_dependency "lograge", "~> 0.14"
  spec.add_dependency "rotp", "~> 6.3"
  spec.add_dependency "rqrcode", "~> 2.2"
  spec.add_dependency "rubyzip", "~> 2.3", ">= 2.3"
end
