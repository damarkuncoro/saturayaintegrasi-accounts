import { test, expect } from '@playwright/test';
import { LoginPage } from '../../support/pages/login-page';
import { TwoFactorPage } from '../../support/pages/two-factor-page';
import { TwoFactorChallengePage } from '../../support/pages/two-factor-challenge-page';
import { SessionsPage } from '../../support/pages/sessions-page';
import { TestUtils } from '../../support/utils/test-utils';
import { TestData } from '../../support/fixtures/test-data';

test.describe('Advanced Authentication', () => {
  test.setTimeout(90000);

  let loginPage: LoginPage;
  let twoFactorPage: TwoFactorPage;
  let twoFactorChallengePage: TwoFactorChallengePage;
  let sessionsPage: SessionsPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    twoFactorPage = new TwoFactorPage(page);
    twoFactorChallengePage = new TwoFactorChallengePage(page);
    sessionsPage = new SessionsPage(page);
  });

  test('should manage 2FA lifecycle', async () => {
    await loginPage.navigate();
    await loginPage.login(TestData.admin.email, TestData.admin.password);
    await loginPage.expectLoggedIn();

    await twoFactorPage.navigate();
    
    // Check state and enable/disable
    const secret = TestUtils.getOtpSecret(TestData.admin.email);
    const otp = TestUtils.generateOtp(secret);
    
    await twoFactorPage.enable(otp, TestData.admin.password);
    await twoFactorPage.expectEnabled();

    const newOtp = TestUtils.generateOtp(secret);
    await twoFactorPage.disable(newOtp, TestData.admin.password);
    await twoFactorPage.expectDisabled();
  });

  test('should challenge for 2FA on login when enabled', async ({ page }) => {
    // 1. Enable 2FA first
    await loginPage.navigate();
    await loginPage.login(TestData.admin.email, TestData.admin.password);
    await loginPage.expectLoggedIn();

    await twoFactorPage.navigate();
    const secret = TestUtils.getOtpSecret(TestData.admin.email);
    const otp = TestUtils.generateOtp(secret);
    await twoFactorPage.enable(otp, TestData.admin.password);
    await twoFactorPage.expectEnabled();

    // 2. Logout
    await loginPage.logout();

    // 3. Login again -> should go to 2FA challenge page
    await loginPage.navigate();
    await loginPage.login(TestData.admin.email, TestData.admin.password);

    await twoFactorChallengePage.expectChallengePage();

    // 4. Try entering invalid OTP code
    await twoFactorChallengePage.verify('000000');
    await twoFactorChallengePage.expectChallengeError();

    // 5. Enter correct OTP code
    const validOtp = TestUtils.generateOtp(secret);
    await twoFactorChallengePage.verify(validOtp);

    // 6. Should be logged in successfully
    await loginPage.expectLoggedIn();

    // 7. Cleanup: disable 2FA
    await twoFactorPage.navigate();
    const disableOtp = TestUtils.generateOtp(secret);
    await twoFactorPage.disable(disableOtp, TestData.admin.password);
    await twoFactorPage.expectDisabled();
  });

  test('should manage active sessions', async () => {
    await loginPage.navigate();
    await loginPage.login(TestData.admin.email, TestData.admin.password);
    await loginPage.expectLoggedIn();

    await sessionsPage.navigate();
    await sessionsPage.expectSessionsVisible();
  });

  test('should revoke active session', async ({ page }) => {
    await loginPage.navigate();
    await loginPage.login(TestData.admin.email, TestData.admin.password);
    await loginPage.expectLoggedIn();

    await sessionsPage.navigate();
    await sessionsPage.expectSessionsVisible();

    // Revoke the session. Since this is the only active session, it will log us out.
    await sessionsPage.revokeFirstSession();

    // Verify it redirects back to login or root
    await page.waitForURL((url) => url.pathname === '/' || url.pathname === '/login', { timeout: 15000 });
    const bodyText = await page.innerText('body');
    expect(bodyText.toLowerCase().includes('logged out') || bodyText.toLowerCase().includes('keluar') || bodyText.toLowerCase().includes('signed out')).toBeTruthy();
  });
});
