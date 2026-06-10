require 'rails_helper'

RSpec.describe UseCases::Identity::Auth::AuthenticateUser do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant, password: 'password123456', password_confirmation: 'password123456') }

  before do
    ActsAsTenant.current_tenant = tenant
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe '#execute' do
    context 'with valid credentials' do
      it 'returns success with token and user' do
        result = described_class.new.execute(
          email: user.email,
          password: 'password123456',
          tenant: tenant
        )

        expect(result[:success]).to be true
        expect(result[:user]).to be_a(Domains::Entities::Identity::UserEntity)
        expect(result[:token]).to be_a(Domains::ValueObjects::Identity::JwtToken)
      end
    end

    context 'with invalid credentials' do
      it 'returns failure' do
        result = described_class.new.execute(
          email: user.email,
          password: 'wrongpassword123',
          tenant: tenant
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Invalid email or password')
      end
    end

    context 'with non-existent email' do
      it 'returns failure' do
        result = described_class.new.execute(
          email: 'nonexistent@example.com',
          password: 'password123456',
          tenant: tenant
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Invalid email or password')
      end
    end
  end
end
