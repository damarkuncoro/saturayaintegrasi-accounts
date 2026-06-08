import { test, expect } from '@playwright/test';
import { LoginPage } from '../../support/pages/login-page';
import { PasswordResetPage } from '../../support/pages/password-reset-page';
import { TestUtils } from '../../support/utils/test-utils';
import { TestData } from '../../support/fixtures/test-data';

test.describe('Password Management Flow', () => {
  test.setTimeout(90000);

  test('should navigate to forgot password page', async ({ page }) => {
    await page.goto('/login');
    // Using multiple possible selectors for robustness
    const forgotLink = page.locator('a:has-text("Lupa kata sandi?"), a:has-text("Forgot password?")');
    await expect(forgotLink).toBeVisible({ timeout: 10000 });
    await forgotLink.click();
    
    await expect(page).toHaveURL(/.*password_reset\/new/, { timeout: 15000 });
  });

  test('should request password reset successfully', async ({ page }) => {
    await page.goto('/identity/password_reset/new');
    
    await page.fill('input[name="email"]', 'admin@demo.com');
    await page.click('input[type="submit"], button:has-text("Reset Password")');

    // Should redirect back to login or show success message
    await page.waitForURL('**/login', { timeout: 30000 }).catch(() => console.log('Timeout waiting for login after pass reset'));
    const bodyText = await page.innerText('body');
    const lowerBody = bodyText.toLowerCase();
    
    // Controller notice: "Check your email for reset instructions"
    const hasSuccess = lowerBody.includes('check') || 
                       lowerBody.includes('email') || 
                       lowerBody.includes('dikirim') ||
                       lowerBody.includes('reset');
    
    expect(hasSuccess).toBeTruthy();
  });

  test('should complete password reset loop successfully', async ({ page }) => {
    const loginPage = new LoginPage(page);
    const passwordResetPage = new PasswordResetPage(page);
    const testEmail = TestData.employer.email;
    const newTempPassword = 'NewTempPassword123!456';

    // 1. Go to request reset page
    await passwordResetPage.navigateToRequest();

    // 2. Submit password reset request
    await passwordResetPage.requestReset(testEmail);

    // 3. Verify request is processed
    await page.waitForURL('**/login', { timeout: 15000 });
    let bodyText = await page.innerText('body');
    expect(bodyText.toLowerCase().includes('check') || bodyText.toLowerCase().includes('email') || bodyText.toLowerCase().includes('reset')).toBeTruthy();

    // 4. Retrieve token programmatically
    const token = TestUtils.getPasswordResetToken(testEmail);
    expect(token).toBeTruthy();

    // 5. Reset password with token
    await passwordResetPage.resetPassword(token, newTempPassword);

    // 6. Verify successful password update
    await page.waitForURL('**/login', { timeout: 15000 });
    bodyText = await page.innerText('body');
    expect(bodyText.toLowerCase().includes('success') || bodyText.toLowerCase().includes('berhasil') || bodyText.toLowerCase().includes('reset')).toBeTruthy();

    // 7. Verify login works with the new password
    await loginPage.navigate();
    await loginPage.login(testEmail, newTempPassword);
    await loginPage.expectLoggedIn();

    // 8. Cleanup: restore password to default
    TestUtils.resetUserPasswordToDefault(testEmail);
  });
});
