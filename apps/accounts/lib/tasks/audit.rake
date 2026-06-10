# frozen_string_literal: true

namespace :system do
  namespace :audit do
    desc "Verifikasi integritas blockchain/rantai hash audit log"
    task verify: :environment do
      puts "🔍 Memulai audit integrity check..."
      total_checked = 0
      corrupted_logs = []

      # Run without tenant scoping to verify all audit logs across all tenants
      ActsAsTenant.without_tenant do
        # We order by created_at, id asc to verify the chain chronologically
        System::AuditLog.order(created_at: :asc, id: :asc).find_each do |log|
          total_checked += 1
          
          # Verify integrity
          unless log.verify_integrity!
            corrupted_logs << { id: log.id, action: log.action, tenant: log.tenant&.name || "Global" }
          end
        end
      end

      puts "✅ Selesai memeriksa #{total_checked} log."

      if corrupted_logs.any?
        puts "🚨 TERDETEKSI KEBOCORAN / MODIFIKASI DATA LOG!"
        corrupted_logs.each do |info|
          puts "  - Log ID: #{info[:id]} | Action: #{info[:action]} | Tenant: #{info[:tenant]}"
        end
        exit 1
      else
        puts "💚 Semua audit log valid dan rantai hash utuh."
      end
    end
  end
end
