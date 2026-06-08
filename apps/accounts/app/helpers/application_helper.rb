module ApplicationHelper
  def format_date(date, format = :default)
    return "-" if date.blank?
    l(date, format: format)
  end

  def format_datetime(time, format = :default)
    return "-" if time.blank?
    l(time, format: format)
  end
  def format_rupiah(number)
    return "Rp 0" if number.blank?
    "Rp #{number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1.')}"
  end
end
