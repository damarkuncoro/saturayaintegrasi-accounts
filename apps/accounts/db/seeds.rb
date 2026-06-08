# Unified seeds.rb for all apps
# Always uses the centralized source of truth from packages/commons

require_relative "../../packages/commons/db/seeds/base"

SatuRayaCommons::Seeder.run
