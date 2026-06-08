module Identity
  # Job untuk menyinkronkan data pengguna ke sistem eksternal secara asinkron.
  # Menggunakan Internal API Client untuk mengirim data ke URL yang dikonfigurasi.
  class UserSyncJob < ApplicationJob
    queue_as :default

    # Menjalankan proses sinkronisasi pengguna.
    # Mengirim data payload ke endpoint sinkronisasi eksternal.
    #
    # @param payload_hash [Hash] Data pengguna dan aksi sinkronisasi yang akan dikirim.
    # @return [Faraday::Response, nil] Mengembalikan respon dari API jika berhasil.
    def perform(payload_hash)
      sync_url = SatuRayaIdentityClient::Identity::BrandConfig.user_sync_url
      return if sync_url.blank?

      # Mengirim data sinkronisasi ke sistem eksternal berdasarkan konfigurasi brand
      SatuRayaCommons::InternalApiClient.post_to_url(
        sync_url,
        "/api/internal/users/sync",
        payload_hash
      )
    rescue => e
      Rails.logger.error("[UserSyncJob] Failed to sync user: #{e.message}")
      raise e
    end
  end
end
