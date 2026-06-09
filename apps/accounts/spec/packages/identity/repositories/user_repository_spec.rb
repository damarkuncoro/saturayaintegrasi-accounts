require 'rails_helper'

RSpec.describe Repositories::Identity::UserRepository do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:repository) { described_class.new }

  describe '#find' do
    it 'returns user entity for valid id' do
      result = repository.find(user.id)

      expect(result).to be_a(Domains::Entities::Identity::UserEntity)
      expect(result.id).to eq(user.id)
      expect(result.email).to eq(user.email)
    end

    it 'returns nil for invalid id' do
      result = repository.find(-1)

      expect(result).to be_nil
    end
  end

  describe '#find_by_email' do
    it 'returns user entity for valid email' do
      result = repository.find_by_email(user.email, tenant: tenant)

      expect(result).to be_a(Domains::Entities::Identity::UserEntity)
      expect(result.email).to eq(user.email)
    end

    it 'returns nil for non-existent email' do
      result = repository.find_by_email('nonexistent@example.com', tenant: tenant)

      expect(result).to be_nil
    end
  end
end
