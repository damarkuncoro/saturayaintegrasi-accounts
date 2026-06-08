module SatuRayaCommons
  class Cache
    def self.fetch(key, expires_in: 1.hour, &block)
      full_key = build_key(key)
      Rails.cache.fetch(full_key, expires_in: expires_in, &block)
    end

    def self.write(key, value, expires_in: 1.hour)
      full_key = build_key(key)
      Rails.cache.write(full_key, value, expires_in: expires_in)
    end

    def self.read(key)
      full_key = build_key(key)
      Rails.cache.read(full_key)
    end

    def self.delete(key)
      full_key = build_key(key)
      Rails.cache.delete(full_key)
    end

    private

    def self.build_key(key)
      tenant_id = ActsAsTenant.current_tenant&.id || "global"
      "satu_raya:v1:#{tenant_id}:#{key}"
    end
  end
end
