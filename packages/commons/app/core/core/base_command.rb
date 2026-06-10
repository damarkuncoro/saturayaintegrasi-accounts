# frozen_string_literal: true

module Core
  class BaseCommand
    include ActiveModel::Model
    include ActiveModel::Attributes
    include Normalizable

    class_attribute :normalizations, default: {}

    # Mendefinisikan normalisasi untuk atribut tertentu.
    # @param attribute [Symbol] Nama atribut
    # @param with [Symbol] Jenis normalisasi (:email, :text, :phone, dll)
    def self.normalize(attribute, with:)
      self.normalizations = normalizations.merge(attribute => with)
    end

    def self.call(params = {})
      instance = new(params)
      instance.send(:apply_normalizations)
      instance.tap(&:validate)
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

    private

    # Menerapkan normalisasi yang telah didefinisikan.
    def apply_normalizations
      self.class.normalizations.each do |attribute, method_suffix|
        value = send(attribute)
        next if value.nil?

        normalization_method = "normalize_#{method_suffix}"
        if respond_to?(normalization_method, true)
          normalized_value = send(normalization_method, value)
          send("#{attribute}=", normalized_value)
        end
      end
    end
  end
end
