# frozen_string_literal: true

require "satu_raya_system/engine"

module SatuRayaSystem
  class << self
    attr_writer :user_class

    def user_class
      @user_class ||= default_user_class
    end

    private

    def default_user_class
      if defined?(::Identity::User)
        ::Identity::User
      elsif defined?(::User)
        ::User
      end
    end
  end
end
