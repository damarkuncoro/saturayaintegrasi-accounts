# frozen_string_literal: true

module Identity
  class Identity::UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :role, :verified, :created_at
end

end