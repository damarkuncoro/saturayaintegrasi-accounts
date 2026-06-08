module Identity
  # Job untuk menyinkronkan data pengguna ke aplikasi eksternal (misalnya: aplikasi Jobs)
  # secara asinkron menggunakan Internal API Client.
  class UserSyncJob < ApplicationJob
    queue_as :default

    # Menjalankan proses sinkronisasi pengguna.
    # Mengirim data payload ke endpoint internal aplikasi Jobs yang dikonfigurasi.
    #
    # @param payload_hash [Hash] Data pengguna dan aksi sinkronisasi yang akan dikirim.
    # @return [Faraday::Response, nil] Mengembalikan respon dari API jika berhasil.
    def perform(payload_hash)
      # Mengirim data sinkronisasi ke aplikasi Jobs berdasarkan konfigurasi brand
      SatuRayaCommons::InternalApiClient.post_to_url(
        SatuRayaIdentityClient::Identity::BrandConfig.jobs_url,
        "/api/internal/users/sync",
        payload_hash
      )
    rescue => e
      Rails.logger.error("[UserSyncJob] Failed to sync user: #{e.message}")
      raise e
    end
  end
end
