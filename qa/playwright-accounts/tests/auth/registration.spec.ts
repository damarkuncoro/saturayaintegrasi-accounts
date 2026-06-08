import { test, expect } from '@playwright/test';
import { RegistrationPage } from '../../support/pages/registration-page';
import { TestUtils } from '../../support/utils/test-utils';
import { TestData } from '../../support/fixtures/test-data';

test.describe('Registration Flow', () => {
  let registrationPage: RegistrationPage;

  test.beforeEach(async ({ page }) => {
    registrationPage = new RegistrationPage(page);
  });

  test('should register a new Worker successfully', async () => {
    const email = TestUtils.generateRandomEmail();
    await registrationPage.navigate();
    await registrationPage.register({
      firstName: 'Bambang',
      lastName: 'Worker',
      email: email,
      phone: '08123456789',
      role: 'worker',
      password: 'Password123!456'
    });
    await registrationPage.expectRegistrationSuccess();
    expect(TestUtils.checkUserVerified(email)).toBe(false);
  });

  test('should register a new Employer successfully', async () => {
    const email = TestUtils.generateRandomEmail();
    await registrationPage.navigate();
    await registrationPage.register({
      firstName: 'Budi',
      lastName: 'Employer',
      email: email,
      phone: '08123456780',
      role: 'employer',
      password: 'Password123!456'
    });
    await registrationPage.expectRegistrationSuccess();
  });

  test('should show validation errors for existing email', async () => {
    await registrationPage.navigate();
    await registrationPage.register({
      firstName: 'Admin',
      lastName: 'Demo',
      email: TestData.admin.email,
      phone: '08123456781',
      role: 'worker',
      password: 'Password123!456'
    });
    await registrationPage.expectRegistrationError();
  });
});
