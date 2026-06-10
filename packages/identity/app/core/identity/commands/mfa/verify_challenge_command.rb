# frozen_string_literal: true

module Identity
  module Commands
    module Mfa
      class VerifyChallengeCommand < ::Core::BaseCommand
        attribute :code, :string

        validates :code, presence: true, length: { minimum: 6, maximum: 6 }
      end
    end
  end
end
