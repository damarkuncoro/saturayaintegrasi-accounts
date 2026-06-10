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

    protected

    # Format tanggal ke format standar (ID)
    def format_date(date, format: "%d %b %Y")
      return "-" if date.nil?
      date.strftime(format)
    end

    # Format datetime ke format standar (ID)
    def format_datetime(datetime, format: "%d %b %Y %H:%M")
      return "-" if datetime.nil?
      datetime.strftime(format)
    end

    # Format mata uang Rupiah
    def format_currency(amount, unit: "Rp")
      return "-" if amount.nil?
      "#{unit} #{number_with_delimiter(amount.to_i, delimiter: '.')}"
    end

    # Helper untuk akses helper view Rails (seperti number_with_delimiter)
    def number_with_delimiter(number, options = {})
      ActionController::Base.helpers.number_with_delimiter(number, options)
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
