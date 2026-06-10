# frozen_string_literal: true

module Core
  class BaseCommand
    include ActiveModel::Model
    include ActiveModel::Attributes

    def self.call(params = {})
      new(params).tap(&:validate)
    end

    def failure?
      errors.any?
    end

    def success?
      !failure?
    end

    def error_messages
      errors.full_messages.to_sentence
    end
  end
end
