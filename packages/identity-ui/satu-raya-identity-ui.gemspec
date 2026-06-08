# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "satu-raya-identity-ui"
  spec.version = "0.1.0"
  spec.authors = ["Satu Raya Integrasi"]
  spec.email = ["dev@saturaya.id"]
  spec.summary = "UI components and views for Satu Raya Identity (IAM)"
  spec.license = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 8.1.3"
end
