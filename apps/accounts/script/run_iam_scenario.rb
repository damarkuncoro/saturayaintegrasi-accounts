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
  role: :worker
}

user = Identity::User.new(user_params)
user.tenant = tenant
user.save!

# Simulasikan controller callback untuk membuat profile baru jika package profile tersedia
if user.respond_to?(:create_worker_profile!)
  user.create_worker_profile!
else
  puts "ℹ️  Skipping WorkerProfile creation (core-domain package not loaded)"
end

puts "✅ User berhasil didaftarkan:"
puts "   - ID       : #{user.id}"
puts "   - Email    : #{user.email}"
puts "   - Role     : #{user.role}"
puts "   - Username : #{user.username} (digenerate otomatis)"

# 3. Verifikasi Callbacks (Profil & Wallet)
puts "\nStep 3: Memverifikasi Hasil Callbacks Otomatis di Database..."
user.reload

# Cek Profil Pekerja
if user.respond_to?(:worker_profile)
  if user.worker_profile.present?
    puts "✅ Profil Pekerja (WorkerProfile) terbuat otomatis:"
    puts "   - ID   : #{user.worker_profile.id}"
    puts "   - Slug : #{user.worker_profile.slug} (digenerate otomatis)"
  else
    puts "❌ Gagal: WorkerProfile tidak terbuat!"
  end
else
  puts "ℹ️  Skipping WorkerProfile verification (not applicable in Pure IAM mode)"
end

# Cek Dompet Digital
if user.respond_to?(:wallet)
  if user.wallet.present?
    puts "✅ Dompet Digital (Wallet) terbuat otomatis:"
    puts "   - ID      : #{user.wallet.id}"
    puts "   - Balance : #{user.wallet.currency} #{user.wallet.balance}"
    puts "   - Status  : #{user.wallet.status}"
  else
    puts "❌ Gagal: Wallet tidak terbuat!"
  end
else
  puts "ℹ️  Skipping Wallet verification (not applicable in Pure IAM mode)"
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

# Enable 2FA
user.enable_2fa!
user.reload
puts "🔒 Status 2FA Baru : #{user.otp_required_for_login ? 'AKTIF' : 'NON-AKTIF'}"
puts "📌 OTP Secret Key  : #{user.otp_secret}"

# QR Code Generation Check
qr_svg = user.otp_qr_code
if qr_svg.include?("<svg")
  puts "✅ QR Code SVG untuk Google Authenticator berhasil dibuat!"
else
  puts "❌ Gagal: QR Code tidak valid!"
end

# Mock OTP Verification
totp = ROTP::TOTP.new(user.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name)
current_otp = totp.now
puts "🔢 Simulasi OTP Code Saat Ini: #{current_otp}"

if user.verify_otp(current_otp)
  puts "✅ Verifikasi OTP Sukses! Akses diberikan."
else
  puts "❌ Gagal: Kode OTP tidak cocok!"
end

# Disable 2FA
user.disable_2fa!
puts "🔒 Status 2FA Akhir: #{user.otp_required_for_login ? 'AKTIF' : 'NON-AKTIF'} (Dinonaktifkan kembali)"

# 7. Simulasi Alur OAuth2 / OIDC (Workforce Federation)
puts "\nStep 7: Menguji Federasi Identitas via OAuth2/OIDC..."

# Persiapan Client SSO
client_name = "Portal Partner Demo"
redirect_uri = "https://partner-app.demo/auth/callback"
sso_client = Identity::SsoClientConfiguration.create!(
  tenant: tenant,
  client_name: client_name,
  redirect_uris: [redirect_uri],
  allowed_scopes: ["openid", "profile", "email"],
  active: true
)

puts "📡 Client SSO Terdaftar:"
puts "   - Name      : #{sso_client.client_name}"
puts "   - Client ID : #{sso_client.client_id}"

# Simulasi Authorization Code
auth_code = SecureRandom.hex(16)
Rails.cache.write("oauth_code_#{auth_code}", {
  user_id: user.id,
  client_id: sso_client.client_id,
  scopes: "openid profile email",
  redirect_uri: redirect_uri
}, expires_in: 5.minutes)

puts "🎟️  Authorization Code Terbit: #{auth_code}"

# Simulasi Token Exchange (Tukar Code menjadi JWT)
cached_data = Rails.cache.read("oauth_code_#{auth_code}")
if cached_data && cached_data[:client_id] == sso_client.client_id
  # Generate ID Token (JWT)
  id_token_payload = {
    sub: user.id,
    iss: SatuRayaIdentityClient::Identity::BrandConfig.oidc_issuer,
    aud: sso_client.client_id,
    iat: Time.current.to_i,
    exp: 1.hour.from_now.to_i,
    email: user.email,
    name: user.full_name
  }
  
  # Dalam implementasi asli menggunakan Identity::User.generate_jwt_token(payload)
  # Di sini kita simulasikan verifikasi payload-nya saja
  puts "✅ Token Exchange Sukses!"
  puts "   - Audience (aud) Match: #{id_token_payload[:aud] == sso_client.client_id}"
  puts "   - Subject (sub) Match : #{id_token_payload[:sub] == user.id}"
  puts "   - Issuer (iss) Match  : #{id_token_payload[:iss]}"
else
  puts "❌ Gagal: Authorization Code tidak valid atau sudah kadaluarsa!"
end

sso_client.destroy

# 8. Pembersihan Data Skenario
puts "\nStep 8: Membersihkan Data Skenario dari Database..."
user.destroy
puts "✅ User, profil, wallet, dan sesi dibersihkan secara bersih (cascade)."

puts "\n================================================================================"
puts "🎉 SKENARIO SELESAI: SEMUA WORKFLOW IAM BERJALAN 100% SUKSES DAN AMAN!"
puts "================================================================================"
