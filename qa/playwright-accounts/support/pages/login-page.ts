import { Page, expect } from '@playwright/test';

export class LoginPage {
  constructor(private page: Page) {}

  async navigate() {
    await this.page.goto('/login');
  }

  async login(email: string, pass: string) {
    console.log(`Attempting login for ${email}...`);
    await this.page.fill('input[type="email"]', email);
    await this.page.fill('input[type="password"]', pass);
    await this.page.click('input[type="submit"], button[type="submit"]');
  }

  async logout() {
    console.log('Attempting logout...');
    await this.page.goto('/dashboard');
    const logoutButton = this.page.locator('main button:has-text("Keluar")');
    await expect(logoutButton).toBeVisible({ timeout: 15000 });
    await logoutButton.click();
    await this.page.waitForURL((url) => url.pathname === '/' || url.pathname === '/login', { timeout: 15000 });
  }

  async expectLoginError() {
    console.log('Verifying login error...');
    // We wait for any text that indicates failure, or the alert component
    await this.page.waitForTimeout(2000); // Wait for potential re-render
    const bodyText = await this.page.innerText('body');
    const lowerBody = bodyText.toLowerCase();
    expect(lowerBody.includes('incorrect') || 
           lowerBody.includes('salah') || 
           lowerBody.includes('invalid') || 
           lowerBody.includes('tidak valid')).toBeTruthy();
  }

  async expectLoggedIn() {
    console.log('Verifying login status on Identity Dashboard...');
    // Identity Dashboard URL: /dashboard
    await this.page.waitForURL('**/dashboard', { timeout: 30000 });
    
    const bodyText = await this.page.innerText('body');
    const lowerBody = bodyText.toLowerCase();
    
    // Check for elements in our new Identity Dashboard
    const isLoggedIn = lowerBody.includes('dashboard') || 
                        lowerBody.includes('keamanan') || 
                        lowerBody.includes('sesi') || 
                        lowerBody.includes('keluar');
                        
    expect(isLoggedIn).toBeTruthy();
  }
}
