require 'rails_helper'

RSpec.describe Identity::UserMailer, type: :mailer do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  describe 'password_reset_instructions' do
    let(:mail) { Identity::UserMailer.password_reset_instructions(user, 'test-token') }

    it 'renders the headers' do
      expect(mail.to).to eq([ user.email ])
    end
  end

  describe 'email_verification_instructions' do
    let(:mail) { Identity::UserMailer.email_verification_instructions(user, 'test-token') }

    it 'renders the headers' do
      expect(mail.to).to eq([ user.email ])
    end
  end
end
