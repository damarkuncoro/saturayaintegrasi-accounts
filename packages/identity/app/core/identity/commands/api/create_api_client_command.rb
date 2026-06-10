# frozen_string_literal: true

module Identity
  module Commands
    module Api
      class CreateApiClientCommand < ::Core::BaseCommand
        attribute :name, :string
        attribute :description, :string
        attribute :scopes, array: true, default: []

        validates :name, presence: true
      end
    end
  end
end
