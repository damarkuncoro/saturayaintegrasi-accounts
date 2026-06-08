module Normalizable
  extend ActiveSupport::Concern

  private

  # @param [String, nil] value
  # @return [String, nil]
  def normalize_email(value)
    value.to_s.strip.downcase.presence
  end

  # @param [String, nil] value
  # @return [String, nil]
  def normalize_key(value)
    value.to_s.strip.downcase.presence
  end

  # @param [String, nil] value
  # @return [String, nil]
  def normalize_text(value)
    value.to_s.strip.presence
  end

  # Menghapus semua karakter non-digit dari nomor telepon
  # @param [String, nil] value
  # @return [String, nil]
  def normalize_phone(value)
    value.to_s.gsub(/\D/, "").presence
  end

  # Memastikan URL memiliki format yang bersih
  # @param [String, nil] value
  # @return [String, nil]
  def normalize_url(value)
    val = value.to_s.strip.downcase
    return nil if val.blank?
    
    val = "https://#{val}" unless val.start_with?("http://", "https://")
    val.presence
  end

  # Membersihkan array dari nilai kosong dan strip setiap elemen
  # @param [Array, nil] values
  # @return [Array]
  def normalize_array(values)
    Array(values).map { |v| v.to_s.strip.presence }.compact.uniq
  end
end
