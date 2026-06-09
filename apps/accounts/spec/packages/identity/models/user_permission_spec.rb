require 'rails_helper'

RSpec.describe Identity::UserPermission, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  describe 'associations' do
    before { ActsAsTenant.current_tenant = nil }
    it { should belong_to(:tenant) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { create(:user_permission, tenant: tenant, user: user) }
    it { should validate_presence_of(:resource_type) }
    it { should validate_presence_of(:action) }
    it { should validate_uniqueness_of(:user_id).scoped_to([ :resource_type, :action ]).with_message('has already been assigned this permission').ignoring_case_sensitivity }

    it "is invalid if user belongs to a different tenant" do
      other_tenant = create(:tenant)
      other_user = create(:user, tenant: other_tenant)
      subject.user = other_user
      expect(subject).not_to be_valid
      expect(subject.errors[:user_id]).to include("must belong to the same tenant")
    end
  end

  describe '.can?' do
    it 'returns true if permission exists' do
      create(:user_permission, user: user, action: 'read', resource_type: 'Recruitment::Job', tenant: tenant)
      expect(Identity::UserPermission.can?(user, 'read', 'Recruitment::Job')).to be true
    end

    it 'normalizes lookup action and resource type' do
      create(:user_permission, user: user, action: 'manage', resource_type: 'Identity::User', tenant: tenant)

      expect(Identity::UserPermission.can?(user, 'MANAGE', 'Identity::User')).to be true
    end

    it 'returns false if permission does not exist' do
      expect(Identity::UserPermission.can?(user, 'read', 'Recruitment::Job')).to be false
    end
  end

  describe 'Identity::User#can?' do
    it 'checks permissions via user object' do
      create(:user_permission, user: user, action: 'manage', resource_type: 'Payroll::Payroll', tenant: tenant)
      expect(user.can?('manage', 'Payroll::Payroll')).to be true
      expect(user.can?('read', 'Payroll::Payroll')).to be false
    end
  end
end
