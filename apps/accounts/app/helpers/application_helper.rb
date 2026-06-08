module ApplicationHelper
  def format_date(date, format = :default)
    return "-" if date.blank?
    l(date, format: format)
  end

  def format_datetime(time, format = :default)
    return "-" if time.blank?
    l(time, format: format)
  end
end
