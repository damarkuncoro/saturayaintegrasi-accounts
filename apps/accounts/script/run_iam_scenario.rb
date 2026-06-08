# frozen_string_literal: true

# Skenario Programmatik IAM Lifecycle di satu-raya-accounts
puts "================================================================================"
puts "🚀 MEMULAI SKENARIO LIFECYCLE IDENTITY & ACCESS MANAGEMENT (IAM)"
puts "================================================================================"

# 1. Mengikat Konteks Tenant (Multi-tenancy check)
puts "\nStep 1: Inisialisasi Tenant..."
tenant = System::Tenant.find_by(slug: "demo") || System::Tenant.create!(name: "Demo Company", slug: "demo", plan: "starter", active: true)
ActsAsTenant.current_tenant = tenant
puts "📌 Berhasil terikat ke Tenant: #{tenant.name} [ID: #{tenant.id}, Slug: #{tenant.slug}]"

# 2. Pendaftaran User Baru (Sign Up & Callbacks)
puts "\nStep 2: Menjalankan Registrasi User Baru..."
email = "test-scenario-#{SecureRandom.hex(4)}@#{SatuRayaIdentityClient::Identity::BrandConfig.app_domain}"
user_params = {
  email: email,
  password: "Password123!456",
  password_confirmation: "Password123!456",
  first_name: "Bambang",
  last_name: "Pamungkas",
  role: :user
}

user = Identity::User.new(user_params)
user.tenant = tenant
user.save!

puts "✅ User berhasil didaftarkan:"
puts "   - ID       : #{user.id}"
puts "   - Email    : #{user.email}"
puts "   - Role     : #{user.role}"
puts "   - Username : #{user.username} (digenerate otomatis)"

# 3. Verifikasi Audit Log
puts "\nStep 3: Memverifikasi Audit Log..."
user.reload
audit_log = System::AuditLog.where(auditable: user).first
if audit_log
  puts "✅ Audit Log ditemukan:"
  puts "   - Action: #{audit_log.action}"
  puts "   - Created At: #{audit_log.created_at}"
else
  puts "❌ Gagal: Audit Log tidak ditemukan!"
end

# 4. Pembuatan Sesi Browser (Session Handshake)
puts "\nStep 4: Membuat Sesi Login Browser Aktif..."
session = user.sessions.create!(
  user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/120.0.0.0",
  ip_address: "192.168.1.100"
)
puts "✅ Sesi berhasil dibuat:"
puts "   - Session ID : #{session.id}"
puts "   - User Agent : #{session.user_agent}"
puts "   - IP Address : #{session.ip_address}"

# 5. Autentikasi API via JWT (JSON Web Token)
puts "\nStep 5: Menguji Penerbitan & Verifikasi Token JWT (Untuk REST API)..."
jwt_token = user.generate_jwt_token
puts "🔑 JWT Token Terbit: #{jwt_token[0..40]}...[TRUNCATED]"

# Decode JWT
decoded_user = Identity::User.decode_jwt_token(jwt_token)
if decoded_user == user
  puts "✅ Verifikasi JWT Sukses! Token didekripsi kembali ke User: #{decoded_user.email}"
else
  puts "❌ Gagal: Token JWT tidak valid atau salah deskripsi!"
end

# 6. Menguji Alur Autentikasi Dua Faktor (2FA / TOTP)
puts "\nStep 6: Menguji Aktivasi Autentikasi Dua Faktor (2FA)..."
puts "🔒 Status 2FA Awal: #{user.otp_required_for_login ? 'AKTIF' : 'NON-AKTIF'}"
user.enable_2fa!
puts "🔒 Status 2FA Setelah Aktivasi: #{user.otp_required_for_login ? 'AKTIF' : 'NON-AKTIF'}"

puts "\n================================================================================"
puts "🏁 SKENARIO IAM SELESAI DENGAN SUKSES"
puts "================================================================================"
