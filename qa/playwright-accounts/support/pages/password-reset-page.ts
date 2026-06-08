import { Page, expect } from '@playwright/test';

export class PasswordResetPage {
  constructor(private page: Page) {}

  async navigateToRequest() {
    console.log('Navigating to Forgot Password request page...');
    await this.page.goto('/identity/password_reset/new');
    await expect(this.page.locator('h1')).toContainText('Forgot your password?');
  }

  async requestReset(email: string) {
    console.log(`Requesting password reset for: ${email}`);
    await this.page.fill('input[name="email"]', email);
    await this.page.click('input[type="submit"]:has-text("Send password reset email")');
  }

  async resetPassword(token: string, newPass: string) {
    console.log(`Performing password reset with token sid: ${token}`);
    await this.page.goto(`/identity/password_reset/edit?sid=${token}`);
    await expect(this.page.locator('h1')).toContainText('Reset your password');
    await this.page.fill('input[name="password"]', newPass);
    await this.page.fill('input[name="password_confirmation"]', newPass);
    await this.page.click('input[type="submit"]:has-text("Save changes")');
  }
}
