# Kontrak Event Asinkron (EVENT-CONTRACT)

Dokumen ini menjelaskan spesifikasi kontrak event (Message/Event Contract) yang dikirim oleh Accounts melalui Event Bus (atau Webhook internal) untuk memberi tahu service lain tentang perubahan siklus hidup identitas pengguna.

---

## 1. Daftar Event Identitas (Identity Event Catalog)

Accounts memublikasikan event setiap kali ada perubahan status atau modifikasi data pengguna yang berdampak pada otorisasi di service lain.

| Nama Event | Pemicu (Trigger) |
| --- | --- |
| `identity.user.created` | Pengguna baru berhasil mendaftar (register). |
| `identity.user.updated` | Perubahan data profil dasar (email, nama, status verifikasi). |
| `identity.user.deleted` | Pengguna dihapus dari sistem (soft-delete atau permanent). |
| `identity.user.suspended` | Akun pengguna ditangguhkan oleh administrator. |
| `identity.user.email_verified`| Pengguna berhasil memverifikasi alamat email mereka. |
| `identity.user.role_changed` | Peran (role) pengguna diubah oleh administrator. |
| `identity.user.permissions_changed`| Hak akses granular (permissions) pengguna diperbarui. |

---

## 2. Struktur Payload Event Standar

Seluruh event yang diterbitkan oleh Accounts wajib mematuhi skema payload JSON seragam berikut:

### Contoh Payload: `identity.user.updated`
```json
{
  "event_id": "c1f7b0a7-bc4e-4f7f-aa7e-976fa8e9324d",
  "event_type": "identity.user.updated",
  "occurred_at": "2026-06-08T10:00:00Z",
  "tenant_id": "c62db73b-b27b-4db4-bfa2-35db4db8b8cb",
  "user": {
    "id": "9f1b98b6-98df-45a8-92c9-12f86db3065b",
    "email": "worker@example.com",
    "role": "worker",
    "active": true,
    "verified": true
  }
}
```

### Penjelasan Skema Payload:
- **`event_id`** (UUID): ID unik event untuk mendukung pemrosesan idempotensi di sisi konsumen (consumer).
- **`event_type`** (String): Jenis event sesuai katalog di atas.
- **`occurred_at`** (DateTime ISO-8601): Waktu kejadian event di server Accounts.
- **`tenant_id`** (UUID): Tenant scope pemilik event untuk menjamin pemrosesan asinkron berjalan pada konteks tenant yang benar.
- **`user`** (Object): Data minimal pengguna yang relevan dengan sinkronisasi:
  - **`id`** (UUID): ID pengguna pusat.
  - **`email`** (String): Alamat email terupdate.
  - **`role`** (String): Peran terupdate.
  - **`active`** (Boolean): Status aktif terkini.
  - **`verified`** (Boolean): Status verifikasi email terkini.

---

## 3. Integritas dan Keamanan Event (HMAC Signature)

Untuk menjamin bahwa event/webhook yang diterima oleh service lain benar-benar berasal dari Accounts dan tidak dimodifikasi di tengah jalan, setiap pengiriman event melalui HTTP wajib menyertakan signature HMAC.

### Mekanisme Tanda Tangan (Signature)
1. Accounts membuat signature menggunakan algoritma **HMAC-SHA256**.
2. Kunci rahasia (**Secret Key**) dibagikan secara aman antar-service via environment variable `HMAC_USER_SYNC_SECRET`.
3. Signature dikirim melalui header HTTP: `X-Satu-Raya-Signature`.

### Contoh Verifikasi (Ruby):
```ruby
class EventVerifier
  def self.verify(payload_body, signature_from_header)
    secret = ENV.fetch("HMAC_USER_SYNC_SECRET")
    expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, payload_body)
    
    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature_from_header)
  end
end
```

Service penerima wajib menolak event jika signature tidak cocok.

---

## Dokumen Terkait
- [Architecture Overview](ARCHITECTURE.md)
- [API Contracts](API-CONTRACT.md)
- [Security Specifications](SECURITY.md)
- [Implementation Roadmap](ROADMAP.md)
