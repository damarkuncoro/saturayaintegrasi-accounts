# frozen_string_literal: true

module UseCases
  module System
    class SyncUserRecord
      def call(attributes)
        action = attributes[:action]
        user_params = attributes[:user_params]

        return ::Core::Result.failure("Action harus diisi.") unless action.present?
        return ::Core::Result.failure("User params harus diisi.") unless user_params.present?

        user_class = SatuRayaSystem.user_class
        return ::Core::Result.failure("User class tidak dikonfigurasi untuk sinkronisasi.") unless user_class

        case action
        when "create", "update"
          # Find or initialize minimal User replica
          user = user_class.find_or_initialize_by(id: user_params[:id])
          
          # Allow simple attributes update
          user.email = user_params[:email] if user_params.key?(:email)
          user.first_name = user_params[:first_name] if user_params.key?(:first_name)
          user.last_name = user_params[:last_name] if user_params.key?(:last_name)
          user.role = user_params[:role] if user_params.key?(:role)
          user.tenant_id = user_params[:tenant_id] if user_params.key?(:tenant_id)
          user.active = user_params[:active] if user_params.key?(:active)
          
          # Assign random secure password to bypass ActiveRecord has_secure_password validations if present
          if user.new_record? && user.respond_to?(:password=)
            random_password = SecureRandom.hex(16)
            user.password = random_password
            user.password_confirmation = random_password
          end

          if user.save
            ::Core::Result.success(user)
          else
            ::Core::Result.failure("Gagal melakukan sinkronisasi user: #{user.errors.full_messages.join(', ')}")
          end
        when "destroy"
          user = user_class.find_by(id: user_params[:id])
          if user
            user.destroy
            ::Core::Result.success({ id: user_params[:id], status: "destroyed" })
          else
            ::Core::Result.success({ id: user_params[:id], status: "not_found" })
          end
        else
          ::Core::Result.failure("Action tidak dikenal: #{action}")
        end
      end
    end
  end
end
