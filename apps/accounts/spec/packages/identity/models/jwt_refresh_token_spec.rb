require "rails_helper"

RSpec.describe Identity::JwtRefreshToken, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:sso_client) { create(:sso_client_configuration, tenant: tenant) }

  describe "validations" do
    it "is valid when tenant, user, and sso_client belong to the same tenant" do
      token = Identity::JwtRefreshToken.new(
        tenant: tenant,
        user: user,
        sso_client_configuration: sso_client,
        token_digest: SecureRandom.hex(32),
        family_id: SecureRandom.uuid,
        expires_at: 1.day.from_now
      )
      expect(token).to be_valid
    end

    it "is invalid when user belongs to a different tenant" do
      other_tenant = create(:tenant)
      other_user = create(:user, tenant: other_tenant)

      token = Identity::JwtRefreshToken.new(
        tenant: tenant,
        user: other_user,
        sso_client_configuration: sso_client,
        token_digest: SecureRandom.hex(32),
        family_id: SecureRandom.uuid,
        expires_at: 1.day.from_now
      )
      expect(token).not_to be_valid
      expect(token.errors[:user_id]).to include("must belong to the same tenant")
    end

    it "is invalid when sso_client belongs to a different tenant" do
      other_tenant = create(:tenant)
      other_sso_client = create(:sso_client_configuration, tenant: other_tenant)

      token = Identity::JwtRefreshToken.new(
        tenant: tenant,
        user: user,
        sso_client_configuration: other_sso_client,
        token_digest: SecureRandom.hex(32),
        family_id: SecureRandom.uuid,
        expires_at: 1.day.from_now
      )
      expect(token).not_to be_valid
      expect(token.errors[:sso_client_configuration_id]).to include("must belong to the same tenant")
    end

    it "sets tenant automatically from user on validation if tenant is not present" do
      token = Identity::JwtRefreshToken.new(
        user: user,
        sso_client_configuration: sso_client,
        token_digest: SecureRandom.hex(32),
        family_id: SecureRandom.uuid,
        expires_at: 1.day.from_now
      )
      expect(token).to be_valid
      expect(token.tenant_id).to eq(tenant.id)
    end
  end
end
