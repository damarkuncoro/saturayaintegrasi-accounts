require 'rails_helper'

RSpec.describe Identity::User, type: :model do
  let(:user) { create(:user) }

  describe '2FA' do
    it 'can enable 2FA' do
      expect { user.enable_2fa! }.to change { user.otp_required_for_login }.from(false).to(true)
      expect(user.otp_secret).to be_present
    end

    it 'can disable 2FA' do
      user.enable_2fa!
      expect { user.disable_2fa! }.to change { user.otp_required_for_login }.from(true).to(false)
      expect(user.otp_secret).to be_nil
    end

    it 'can verify OTP' do
      user.enable_2fa!
      totp = ROTP::TOTP.new(user.otp_secret)
      valid_code = totp.now
      expect(user.verify_otp(valid_code)).to be_truthy
      expect(user.verify_otp('000000')).to be_falsy
    end

    it 'generates SVG QR code' do
      user.enable_2fa!
      expect(user.otp_qr_code).to include('<svg')
    end
  end
end
