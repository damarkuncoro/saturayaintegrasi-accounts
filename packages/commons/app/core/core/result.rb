module Core
  # Result Object Pattern untuk standarisasi return value dari Use Cases.
  # Menghindari penggunaan hash { success: true, ... } yang tidak konsisten.
  class Result
    attr_reader :value, :error, :meta

    # Inisialisasi objek Result.
    # @param success [Boolean] Status keberhasilan.
    # @param value [Object] Data yang dikembalikan jika sukses.
    # @param error [String, Hash] Pesan error atau detail error jika gagal.
    # @param meta [Hash] Metadata tambahan (misal: pagination, breadcrumbs).
    def initialize(success, value: nil, error: nil, meta: {})
      @success = success
      @value = value
      @error = error
      @meta = meta
    end

    # Factory method untuk sukses.
    def self.success(value = nil, meta: {})
      new(true, value: value, meta: meta)
    end

    # Factory method untuk gagal.
    def self.failure(error, meta: {})
      new(false, error: error, meta: meta)
    end

    # Mengecek apakah operasi sukses.
    def success?
      @success
    end

    # Mengecek apakah operasi gagal.
    def failure?
      !@success
    end

    # Akses gaya Hash untuk kompatibilitas ke belakang (backwards compatibility).
    def [](key)
      if @value.is_a?(Hash) && @value.key?(key)
        @value[key]
      elsif key == :success || key == "success"
        success?
      elsif key == :error || key == "error"
        @error
      elsif key == :value || key == "value"
        @value
      elsif key == :meta || key == "meta"
        @meta
      elsif @meta.is_a?(Hash) && @meta.key?(key)
        @meta[key]
      elsif @value && @value.class.respond_to?(:name) && 
            (val_name = @value.class.name.split("::").last.underscore) &&
            (val_name.to_sym == key.to_sym || val_name.include?(key.to_s))
        @value
      elsif @value.respond_to?(:[])
        begin
          @value[key]
        rescue StandardError
          nil
        end
      else
        nil
      end
    end




    # Callback jika sukses.
    def on_success
      yield(value, meta) if success?
      self
    end

    # Callback jika gagal.
    def on_failure
      yield(error, meta) if failure?
      self
    end
  end
end
