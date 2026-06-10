# frozen_string_literal: true

module SatuRayaCommons
  module ResultHandler
    extend ActiveSupport::Concern

    protected

    # Menangani objek Core::Result dan memberikan respon yang sesuai.
    # @param result [Core::Result]
    # @param success_path [String] URL redirect jika sukses (opsional)
    # @param failure_path [String] URL redirect jika gagal (opsional)
    # @param notice [String] Pesan sukses (opsional)
    # @yield [value, meta] Blok kustom jika sukses
    def handle_result(result, success_path: nil, failure_path: nil, notice: nil, &block)
      if result.success?
        if block_given?
          block.call(result.value, result.meta)
        elsif success_path
          redirect_to success_path, notice: notice || result.meta[:message] || "Operasi berhasil."
        end
      else
        if failure_path
          redirect_to failure_path, alert: result.error
        else
          yield(result.error, result.code, result.meta) if block_given? && block.arity > 2
          render_error(result) unless performed?
        end
      end
    end

    private

    def render_error(result)
      status = result.meta[:status] || :bad_request
      respond_to do |format|
        format.html do
          flash.now[:alert] = result.error
          render_error_page(status)
        end
        format.json do
          render json: { 
            error: result.error, 
            code: result.code,
            meta: result.meta 
          }.compact, status: status
        end
      end
    end

    def render_error_page(status)
      # Implementasi render view error sesuai status jika diperlukan
      render status: status
    end
  end
end
