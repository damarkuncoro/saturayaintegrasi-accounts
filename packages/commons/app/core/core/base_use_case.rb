# frozen_string_literal: true

module Core
  class BaseUseCase
    # Method class untuk mempermudah pemanggilan use case.
    # @example User::Register.call(params: { ... })
    def self.call(*args, **kwargs)
      new.execute(*args, **kwargs)
    end

    # Method utama yang menjalankan logika use case.
    def execute(*args, **kwargs)
      if self.class.transactional?
        ActiveRecord::Base.transaction do
          perform_execute(*args, **kwargs)
        end
      else
        perform_execute(*args, **kwargs)
      end
    rescue => e
      handle_exception(e)
    end

    def perform_execute(*args, **kwargs)
      raise NotImplementedError, "#{self.class} harus mengimplementasikan method #perform_execute"
    end

    def self.transactional?
      @transactional || false
    end

    def self.transactional!
      @transactional = true
    end

    protected

    # Melakukan otorisasi aksi menggunakan Pundit.
    # @param record [Object] Objek yang akan diperiksa aksesnya
    # @param query [Symbol] Nama method policy (misal: :update?)
    # @param user [Object] User yang melakukan aksi
    # @raise [Pundit::NotAuthorizedError] jika tidak diizinkan
    def authorize!(record, query, user: nil)
      user ||= System::Current.user
      policy = Pundit.policy!(user, record)
      
      unless policy.public_send(query)
        raise Pundit::NotAuthorizedError, query: query, record: record, policy: policy
      end
    end

    # Menangani exception secara standar jika tidak dihandle di subclass.
    def handle_exception(e)
      case e
      when Pundit::NotAuthorizedError
        failure("Anda tidak memiliki izin untuk melakukan aksi ini.", code: :forbidden, meta: { status: :forbidden })
      else
        Rails.logger.error "[#{self.class}] Error: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
        
        failure("Terjadi kesalahan sistem.", code: :system_error)
      end
    end

    # Helper untuk logging audit jika tersedia.
    def audit_log(action:, auditable:, tenant:, metadata: {})
      if defined?(::Services::System::AuditLogger)
        ::Services::System::AuditLogger.log(
          action: action,
          auditable: auditable,
          tenant: tenant,
          metadata: metadata
        )
      end
    end

    # Helper untuk membungkus hasil sukses.
    def success(value = nil, meta: {})
      ::Core::Result.success(value, meta: meta)
    end

    # Helper untuk membungkus hasil gagal.
    def failure(error, code: nil, meta: {})
      ::Core::Result.failure(error, code: code, meta: meta)
    end

    # Helper untuk validasi input menggunakan command object.
    # @param command_class [Class] Kelas command yang mewarisi Core::BaseCommand
    # @param params [Hash] Parameter input
    # @return [Core::BaseCommand]
    def validate_with(command_class, params)
      command = command_class.call(params)
      if command.failure?
        # Kita tidak langsung return failure di sini agar subclass bisa menghandle detailnya
        # tapi menyediakan helper untuk mempermudah.
      end
      command
    end
  end
end
