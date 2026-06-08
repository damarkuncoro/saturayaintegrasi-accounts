import { Page, expect } from '@playwright/test';

export class TwoFactorPage {
  constructor(private page: Page) {}

  async navigate() {
    await this.page.goto('/two_factor_settings');
    await expect(this.page.locator('input[name="otp_code"]')).toBeVisible({ timeout: 15000 });
  }

  async enable(otpCode: string, passwordChallenge: string) {
    await this.page.fill('input[name="otp_code"]', otpCode);
    await this.page.fill('input[name="password_challenge"]', passwordChallenge);
    await this.page.click('input[type="submit"]:has-text("Aktifkan 2FA")');
  }

  async disable(otpCode: string, passwordChallenge: string) {
    await this.page.fill('input[name="otp_code"]', otpCode);
    await this.page.fill('input[name="password_challenge"]', passwordChallenge);
    await this.page.click('input[type="submit"]:has-text("Nonaktifkan 2FA")');
  }

  async expectEnabled() {
    await expect(this.page.locator('text=Status: Aktif')).toBeVisible();
    await expect(this.page.locator('text=berhasil diaktifkan')).toBeVisible();
  }

  async expectDisabled() {
    await expect(this.page.locator('text=Status: Tidak Aktif')).toBeVisible();
    await expect(this.page.locator('text=berhasil dinonaktifkan')).toBeVisible();
  }
}
