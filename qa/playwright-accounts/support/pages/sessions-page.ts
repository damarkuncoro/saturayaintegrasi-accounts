import { Page, expect } from '@playwright/test';

export class SessionsPage {
  constructor(private page: Page) {}

  async navigate() {
    await this.page.goto('/sessions');
  }

  async expectSessionsVisible() {
    await expect(this.page.locator('h1')).toContainText('Devices & Sessions');
    const sessionCount = await this.page.locator('#sessions > div').count();
    expect(sessionCount).toBeGreaterThan(0);
  }

  async revokeFirstSession() {
    const logoutButton = this.page.locator('button:has-text("Log out")').first();
    await logoutButton.click();
  }
}
