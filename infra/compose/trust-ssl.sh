#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=========================================================="
echo "🔒 Memulai Otomatisasi Trust SSL Certificate Caddy lokal"
echo "=========================================================="

# 1. Pastikan container Caddy sedang berjalan
if ! docker ps | grep -q satu-raya-caddy-dev; then
  echo "⚠️  Container Caddy tidak terdeteksi aktif. Mencoba menyalakan..."
  docker compose up -d caddy
  sleep 2
fi

# 2. Salin sertifikat root dari container Caddy ke folder lokal
echo "📥 Mengambil Root CA certificate dari container Caddy..."
docker cp satu-raya-caddy-dev:/data/caddy/pki/authorities/local/root.crt ./caddy-root.crt

# 3. Masukkan ke dalam macOS System Keychain sebagai tepercaya
echo "🔑 Memasukkan sertifikat ke macOS System Keychain..."
echo "👉 Anda mungkin diminta memasukkan kata sandi administrator (sudo) Mac Anda:"
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./caddy-root.crt

# 4. Hapus file sertifikat sementara
rm ./caddy-root.crt

echo "=========================================================="
echo "✅ SUKSES! Sertifikat Caddy berhasil dipercayai oleh macOS!"
echo "👉 Silakan tutup dan buka kembali (restart) browser Google Chrome Anda."
echo "=========================================================="
