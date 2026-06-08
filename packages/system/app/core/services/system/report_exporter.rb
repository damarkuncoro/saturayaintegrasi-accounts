require "csv"

module Services
  module System
  class ReportExporter
    # @param data [ActiveRecord::Relation, Array]
    # @param columns [Array<Symbol, String>]
    # @return [String] CSV content
    def self.to_csv(data, columns)
      CSV.generate(headers: true) do |csv|
        csv << columns.map { |c| c.to_s.humanize.upcase }

        data.each do |record|
          csv << columns.map do |column|
            value = record.respond_to?(column) ? record.send(column) : record[column]
            format_value(value)
          end
        end
      end
    end

    private

    def self.format_value(value)
      case value
      when Time, DateTime
        value.in_time_zone("Jakarta").strftime("%d/%m/%Y %H:%M")
      when Date
        value.strftime("%d/%m/%Y")
      when BigDecimal, Float
        # Format Rupiah standar Indonesia
        "Rp #{ActionController::Base.helpers.number_with_delimiter(value.to_i, delimiter: '.', separator: ',')}"
      else
        value
    end
  end
end
end

end