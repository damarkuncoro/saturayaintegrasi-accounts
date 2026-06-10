# frozen_string_literal: true

module Core
  class BaseUseCase
    # Method utama yang harus diimplementasikan oleh subclass.
    def execute(*args, **kwargs)
      if self.class.transactional?
        ActiveRecord::Base.transaction do
          perform_execute(*args, **kwargs)
        end
      else
        perform_execute(*args, **kwargs)
      end
    end

    def perform_execute(*args, **kwargs)
      raise NotImplementedError, "#{self.class} harus mengimplementasikan method #perform_execute atau #execute"
    end

    def self.transactional?
      @transactional || false
    end

    def self.transactional!
      @transactional = true
    end

    protected

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
  end
end
