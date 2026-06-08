import { test, expect } from '@playwright/test';
import { LoginPage } from '../../support/pages/login-page';
import { TestData } from '../../support/fixtures/test-data';

test.describe('Authentication Flow', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
  });

  test('should login successfully with valid credentials', async () => {
    await loginPage.navigate();
    await loginPage.login(TestData.admin.email, TestData.admin.password);
    await loginPage.expectLoggedIn();
  });

  test('should show error message with invalid credentials', async () => {
    await loginPage.navigate();
    await loginPage.login('wrong@demo.com', 'WrongPassword123');
    await loginPage.expectLoginError();
  });

  test('should logout successfully', async ({ page }) => {
    await loginPage.navigate();
    await loginPage.login(TestData.admin.email, TestData.admin.password);
    await loginPage.expectLoggedIn();
    await loginPage.logout();
    
    // Verify logout: visiting /dashboard should redirect back to login
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/.*login/);
  });
});
