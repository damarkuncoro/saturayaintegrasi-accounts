# frozen_string_literal: true

module Services
  module System
    class ErrorSubscriber
      # Centralized Error Handling untuk Satu Raya.
      # Berfungsi menangkap exception dari Rails.error.handle/report
      # dan mengirimkannya ke logging service (Rails Logger, Sentry, dll).
      def report(error, handled:, severity:, context:, source: nil)
        # Log ke Rails Logger dengan format terstruktur
        safe_context = sanitize_context(context)
        Rails.logger.error(
          "[ErrorSubscriber] #{severity.to_s.upcase}: #{error.message} " \
          "source=#{source} handled=#{handled} context=#{safe_context.to_json}"
        )

        # Jika di production, kita bisa kirim ke Sentry/Honeybadger di sini
        # if Rails.env.production?
        #   Sentry.capture_exception(error, extra: context, tags: { source: source })
        # end

        # Opsional: Kirim alert ke Slack/Discord untuk error kritis
        # if severity == :error && !handled
        #   Services::SlackNotifier.alert_error(error, context)
        # end
      end

      private

      def sanitize_context(context)
        return {} unless context.is_a?(Hash)

        context.each_with_object({}) do |(key, value), hash|
          hash[key] = case value
                      when String, Symbol, Numeric, TrueClass, FalseClass, NilClass
                        value
                      when Hash
                        sanitize_context(value)
                      when Array
                        value.map { |v| v.is_a?(Hash) ? sanitize_context(v) : v.to_s }
                      else
                        if value.respond_to?(:id) && value.respond_to?(:class)
                          { class: value.class.name, id: value.id }
                        else
                          value.to_s.truncate(200)
                        end
                      end
        end
      rescue StandardError => e
        { error: "Failed to sanitize context: #{e.message}" }
      end
    end
  end
end
