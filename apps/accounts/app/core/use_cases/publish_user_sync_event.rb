module UseCases
  # Use Case untuk mempublikasikan event sinkronisasi data pengguna ke sistem lain
  # melalui background job. Memastikan data pengguna yang relevan dikirim secara asinkron.
  class PublishUserSyncEvent
    # Menjalankan proses publikasi event sinkronisasi pengguna.
    #
    # @param action [String] Jenis aksi yang memicu sinkronisasi (misal: 'create', 'update', 'delete').
    # @param user [Identity::User] Objek user yang datanya akan disinkronkan.
    # @return [ActiveJob::Base] Mengembalikan instance background job yang telah dijadwalkan.
    def call(action:, user:)
      payload = {
        action: action,
        user: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          tenant_id: user.tenant_id,
          active: user.active
        }
      }
      ::Identity::UserSyncJob.perform_later(payload)
    end
  end
end
