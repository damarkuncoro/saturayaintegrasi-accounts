# frozen_string_literal: true

module Core
  class BasePresenter
    attr_reader :object, :view_context

    def initialize(object, view_context = nil)
      @object = object
      @view_context = view_context
    end

    def self.wrap(collection, view_context = nil)
      collection.map { |obj| new(obj, view_context) }
    end

    def as_json(_options = {})
      raise NotImplementedError, "#{self.class} harus mengimplementasikan method #as_json"
    end

    private

    def h
      view_context
    end

    def method_missing(method, *args, &block)
      if object.respond_to?(method)
        object.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      object.respond_to?(method, include_private) || super
    end
  end
end
