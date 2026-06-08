import { Page, expect } from '@playwright/test';

export class RegistrationPage {
  constructor(private page: Page) {}

  async navigate() {
    await this.page.goto('/register');
  }

  async register(user: { firstName: string, lastName: string, email: string, phone: string, role: 'worker' | 'employer', password: string }) {
    await this.page.fill('input[name="user[first_name]"]', user.firstName);
    await this.page.fill('input[name="user[last_name]"]', user.lastName);
    await this.page.fill('input[name="user[email]"]', user.email);
    await this.page.fill('input[name="user[phone]"]', user.phone);
    // Role selection using the label or value
    await this.page.selectOption('select[name="user[role]"]', { value: user.role });
    await this.page.fill('input[name="user[password]"]', user.password);
    await this.page.fill('input[name="user[password_confirmation]"]', user.password);
    await this.page.click('input[type="submit"], button[type="submit"]');
  }

  async expectRegistrationSuccess() {
    await this.page.waitForURL('**/dashboard', { timeout: 45000 }).catch(() => {});
    const bodyText = await this.page.innerText('body');
    const lowerBody = bodyText.toLowerCase();
    expect(lowerBody.includes('dashboard') || lowerBody.includes('welcome') || lowerBody.includes('sukses')).toBeTruthy();
  }

  async expectRegistrationError() {
    await this.page.waitForSelector('.bg-rose-50, .alert, [role="alert"]', { timeout: 15000 });
    const bodyText = await this.page.innerText('body');
    const lowerBody = bodyText.toLowerCase();
    const hasError = lowerBody.includes('sudah digunakan') || 
                     lowerBody.includes('taken') || 
                     lowerBody.includes('kesalahan') || 
                     lowerBody.includes('error');
    expect(hasError).toBeTruthy();
  }
}
