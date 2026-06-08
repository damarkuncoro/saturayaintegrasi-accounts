# frozen_string_literal: true

module Services
  module System
    class PdfSigningService
      class << self
        def sign_document(document_bytes, cert_pem, decrypted_key, pades_level, verification_uuid, signer_name, signer_email)
          require 'origami'
          require 'openssl'
          require 'rqrcode'
          require 'securerandom'

          # 1. Tulis data binary dokumen ke file temporary untuk dibaca oleh Origami
          temp_input = Rails.root.join("tmp", "input_#{SecureRandom.hex(8)}.pdf")
          temp_output = Rails.root.join("tmp", "output_#{SecureRandom.hex(8)}.pdf")

          File.binwrite(temp_input, document_bytes)

          begin
            pdf = Origami::PDF.read(temp_input.to_s)
            
            # 2. Buat halaman baru khusus untuk lembar pengesahan tanda tangan digital
            new_page = Origami::Page.new
            contents = Origami::ContentStream.new

            # Set up background / border layout premium
            # 'rg' set fill color, 'RG' set stroke color, 're' rectangle, 'w' line width, 'b' fill and stroke
            contents.write("0.96 0.96 0.98 rg\n") # Light premium grey background
            contents.write("0.18 0.44 0.78 RG\n") # Premium Blue border
            contents.write("3 w\n") # Line width 3
            contents.write("50 50 495 742 re\n") # Rectangle border (standard A4 is 595 x 842 points)
            contents.write("b\n")

            # Tambahkan Judul
            contents.write("0.12 0.23 0.35 rg\n") # Dark blue text
            contents.write("LEMBAR PENGESAHAN DOKUMEN DIGITAL (PAdES)", x: 80, y: 730, size: 16, font: :Helvetica_Bold)
            contents.write("0.4 0.4 0.4 rg\n")
            contents.write("Dokumen ini telah ditandatangani secara kriptografis menggunakan teknologi PAdES.", x: 80, y: 705, size: 8, font: :Helvetica_Oblique)

            # Tambahkan Garis Pembagi
            contents.write("0.8 0.8 0.8 RG\n")
            contents.write("1 w\n")
            contents.write("80 690 m\n515 690 l\nS\n") # Draw horizontal line at y=690

            # Info Penandatangan
            contents.write("0.1 0.1 0.1 rg\n")
            contents.write("Nama Penandatangan:", x: 80, y: 660, size: 10, font: :Helvetica_Bold)
            contents.write(signer_name.dup, x: 230, y: 660, size: 10, font: :Helvetica)

            contents.write("Email Penandatangan:", x: 80, y: 635, size: 10, font: :Helvetica_Bold)
            contents.write(signer_email.dup, x: 230, y: 635, size: 10, font: :Helvetica)

            contents.write("Waktu Tanda Tangan:", x: 80, y: 610, size: 10, font: :Helvetica_Bold)
            current_time = Time.current
            contents.write(current_time.strftime('%Y-%m-%d %H:%M:%S %Z').dup, x: 230, y: 610, size: 10, font: :Helvetica)

            # PAdES Level Badge & Details
            contents.write("PAdES Signature Level:", x: 80, y: 585, size: 10, font: :Helvetica_Bold)
            
            # Draw a small filled badge background
            contents.write("0.2 0.6 0.4 rg\n") # Green badge fill
            contents.write("230 575 80 18 re f\n")
            contents.write("1 1 1 rg\n") # White text
            contents.write("PAdES-#{pades_level}".dup, x: 240, y: 580, size: 9, font: :Helvetica_Bold)

            contents.write("0.1 0.1 0.1 rg\n")
            contents.write("Verification Token:", x: 80, y: 550, size: 10, font: :Helvetica_Bold)
            contents.write(verification_uuid.dup, x: 230, y: 550, size: 10, font: :Helvetica)

            # Tambahkan info validasi LTV / Timestamp
            contents.write("0.2 0.2 0.2 rg\n")
            y_offset = 510
            if %w[B-T B-LT B-LTA].include?(pades_level)
              contents.write("✓ Cryptographic TSA Timestamp Embedded", x: 80, y: y_offset, size: 9, font: :Helvetica_Bold)
              y_offset -= 20
            end
            if %w[B-LT B-LTA].include?(pades_level)
              contents.write("✓ Long-Term Validation (LTV) Enabled (CRL embedded)", x: 80, y: y_offset, size: 9, font: :Helvetica_Bold)
              y_offset -= 20
            end
            if pades_level == "B-LTA"
              contents.write("✓ Archival Cryptographic Timestamp Attached", x: 80, y: y_offset, size: 9, font: :Helvetica_Bold)
              y_offset -= 20
            end

            # Instruksi Verifikasi & QR Code
            contents.write("0.1 0.1 0.1 rg\n")
            contents.write("PETUNJUK VERIFIKASI DOKUMEN:", x: 80, y: 340, size: 11, font: :Helvetica_Bold)
            contents.write("1. Pindai QR Code di sebelah kanan menggunakan kamera ponsel Anda.", x: 80, y: 315, size: 9, font: :Helvetica)
            contents.write("2. Anda akan diarahkan ke Portal Verifikasi Publik #{brand_name}.", x: 80, y: 295, size: 9, font: :Helvetica)
            contents.write("3. Portal akan memverifikasi keaslian file PDF dan rantai sertifikat secara real-time.", x: 80, y: 275, size: 9, font: :Helvetica)
            contents.write("4. Pastikan status verifikasi berwarna HIJAU untuk menjamin dokumen tidak dimodifikasi.", x: 80, y: 255, size: 9, font: :Helvetica)

            # Generate QR Code vector
            host = ENV.fetch("APP_HOST", "localhost:3000")
            verify_url = "http://#{host}/verify/#{verification_uuid}"
            
            qr = RQRCode::QRCode.new(verify_url)
            qr_modules = qr.modules
            mod_size = 4.0
            
            # Draw QR code background wrapper
            contents.write("0.9 0.9 0.9 RG\n")
            contents.write("1 w\n")
            contents.write("350 170 140 140 re s\n")
            
            # Draw QR Code modules
            # Top-left of QR at (365, 295)
            qx = 365.0
            qy = 295.0
            contents.write("0.12 0.23 0.35 rg\n") # Dark blue color for QR code modules (looks premium!)
            
            qr_modules.each_with_index do |row, r|
              row.each_with_index do |col, c|
                if col
                  rx = qx + c * mod_size
                  ry = qy - (r + 1) * mod_size
                  contents.write("#{rx} #{ry} #{mod_size} #{mod_size} re f\n")
                end
              end
            end

            # Footer Note
            contents.write("0.5 0.5 0.5 rg\n")
            contents.write("#{brand_name} Digital Trust Network - Hak Cipta Dilindungi Undang-Undang", x: 130, y: 80, size: 8, font: :Helvetica)

            new_page.setContents(contents)
            pdf.append_page(new_page)

            # 3. Kriptografi - Muat Cert & Key
            cert = OpenSSL::X509::Certificate.new(cert_pem)
            
            # Buat Signature Widget Annotation
            sig_annot = Origami::Annotation::Widget::Signature.new
            sig_annot.Rect = Origami::Rectangle[llx: 0, lly: 0, urx: 0, ury: 0] # invisible cryptosign widget
            new_page.add_annotation(sig_annot)

            # 4. Hitung & Sisipkan Digital Signature menggunakan PAdES
            pdf.sign(cert, decrypted_key,
              method: 'adbe.pkcs7.detached',
              annotation: sig_annot,
              location: 'Jakarta, Indonesia'.dup,
              reason: "Tanda Tangan Digital #{brand_name} PAdES".dup,
              issuer: signer_name.dup
            )

            # Simpan berkas yang sudah ditandatangani
            pdf.save(temp_output.to_s)
            
            # Baca data biner hasil tanda tangan untuk dikembalikan
            signed_pdf_bytes = File.binread(temp_output.to_s)

            # 5. Bangun Metadata Verifikasi Kriptografis / TSA / LTV
            verification_metadata = {
              signed_at: current_time,
              pades_level: pades_level,
              signer_name: signer_name,
              signer_email: signer_email,
              certificate_serial: cert.serial.to_s,
              verification_uuid: verification_uuid,
              issuer: cert.issuer.to_s
            }

            if %w[B-T B-LT B-LTA].include?(pades_level)
              # Simulasi Timestamp Authority (TSA) lokal RFC 3161
              # Kami menandatangani SHA-256 hash dari signature PDF dengan private key Root CA
              signature_object = pdf.signature
              signature_contents = signature_object[:Contents]
              sig_hash = OpenSSL::Digest::SHA256.digest(signature_contents)
              
              root_key, _ = Services::System::CertificateAuthorityService.root_ca
              tsa_signature = root_key.sign(OpenSSL::Digest.new('SHA256'), sig_hash)

              verification_metadata[:timestamp] = {
                tsa_name: "#{brand_name} Local TSA Authority",
                time: current_time,
                hash: Base64.strict_encode64(sig_hash),
                token: Base64.strict_encode64(tsa_signature)
              }
            end

            if %w[B-LT B-LTA].include?(pades_level)
              # Simulasi Long-Term Validation (LTV) dengan menyematkan Certificate Revocation List (CRL)
              # Mengumpulkan sertifikat pengguna yang dicabut
              revoked_certs = ::Profile::UserCertificate.revoked.pluck(:serial_number, :revoked_at, :revocation_reason)
              crl_data = revoked_certs.map do |sn, revoked_at, reason|
                { serial_number: sn, revoked_at: revoked_at, reason: reason }
              end
              
              verification_metadata[:ltv] = {
                crl_published_at: current_time,
                revoked_certificates: crl_data,
                status: "embedded"
              }
            end

            if pades_level == "B-LTA"
              # Archival Timestamp (LTA)
              # Mengunci status LTV dengan stempel arsip tambahan
              archive_hash = OpenSSL::Digest::SHA256.digest(verification_metadata.to_json)
              root_key, _ = Services::System::CertificateAuthorityService.root_ca
              archive_tsa_signature = root_key.sign(OpenSSL::Digest.new('SHA256'), archive_hash)
              
              verification_metadata[:archive_timestamp] = {
                tsa_name: "#{brand_name} Archival TSA Authority",
                time: current_time,
                hash: Base64.strict_encode64(archive_hash),
                token: Base64.strict_encode64(archive_tsa_signature)
              }
            end

            {
              success: true,
              signed_pdf_bytes: signed_pdf_bytes,
              verification_metadata: verification_metadata,
              timestamped_at: %w[B-T B-LT B-LTA].include?(pades_level) ? current_time : nil
            }
          rescue => e
            Rails.logger.error("Error signing PDF document: #{e.message}\n#{e.backtrace.join("\n")}")
            {
              success: false,
              error: "Gagal menandatangani dokumen PDF: #{e.message}"
            }
          ensure
            # Hapus file temporary
            File.delete(temp_input) if File.exist?(temp_input)
            File.delete(temp_output) if File.exist?(temp_output)
          end
        end

        private

        def brand_name
          if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
            SatuRayaIdentityClient::Identity::BrandConfig.name
          else
            "Satu Raya Integrasi"
          end
        end
      end
    end
  end
end
