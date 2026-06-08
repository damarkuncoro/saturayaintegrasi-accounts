module Domains
  module ValueObjects
    module Identity
    class Availability
      VALID_STATUSES = %w[full-time part-time freelance gig unavailable].freeze

      attr_reader :status

      def initialize(status)
        @status = status
      end

      def valid?
        VALID_STATUSES.include?(status)
      end

      def full_time?
        status == "full-time"
      end

      def part_time?
        status == "part-time"
      end

      def freelance?
        status == "freelance"
      end
    end
  end
end

end