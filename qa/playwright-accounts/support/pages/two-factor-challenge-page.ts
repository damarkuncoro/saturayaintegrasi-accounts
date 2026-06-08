import { Page, expect } from '@playwright/test';

export class TwoFactorChallengePage {
  constructor(private page: Page) {}

  async expectChallengePage() {
    console.log('Verifying we are on the 2FA challenge page...');
    await expect(this.page).toHaveURL(/.*two_factor_challenge/, { timeout: 15000 });
    await expect(this.page.locator('input[name="otp_code"]')).toBeVisible({ timeout: 15000 });
  }

  async verify(otpCode: string) {
    console.log(`Submitting OTP code: ${otpCode}`);
    await this.page.fill('input[name="otp_code"]', otpCode);
    await this.page.click('input[type="submit"]:has-text("Verifikasi & Masuk")');
  }

  async expectChallengeError() {
    console.log('Verifying 2FA challenge error alert is visible...');
    await expect(this.page.locator('.alert, [role="alert"]')).toBeVisible({ timeout: 10000 });
    const bodyText = await this.page.innerText('body');
    expect(bodyText.toLowerCase().includes('tidak valid') || bodyText.toLowerCase().includes('invalid')).toBeTruthy();
  }
}
