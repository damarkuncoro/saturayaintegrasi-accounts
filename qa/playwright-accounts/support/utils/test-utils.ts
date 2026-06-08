import { execSync } from 'child_process';
import { generateSync } from 'otplib';
import path from 'path';

const composeDir = path.resolve(__dirname, '../../../../infra/compose');
const workspaceRoot = path.resolve(composeDir, '../..');
const composeFile = path.join(composeDir, 'docker-compose.yml');
const composeOverrideFile = path.join(composeDir, 'docker-compose.override.yml');
const envFile = path.join(workspaceRoot, '.env');
const composeCommand = [
  'docker compose',
  `--project-directory ${composeDir}`,
  `--env-file ${envFile}`,
  `-f ${composeFile}`,
  `-f ${composeOverrideFile}`,
].join(' ');

export class TestUtils {
  static runDocker(cmd: string): string {
    try {
      return execSync(`${composeCommand} ${cmd}`, { encoding: 'utf-8' }).trim();
    } catch (e) {
      console.warn(`Docker command failed, attempting local fallback: ${cmd}`);
      return execSync(`cd ${workspaceRoot}/apps/accounts && bundle exec ${cmd.split('bin/rails runner')[1].replace(/"/g, '')}`, { encoding: 'utf-8' }).trim();
    }
  }

  static getOtpSecret(email: string): string {
    return this.runDocker(`exec -T accounts-app bin/rails runner "puts Identity::User.find_by(email: '${email}').otp_secret"`);
  }

  static generateOtp(secret: string): string {
    return generateSync({ secret: secret });
  }

  static checkUserVerified(email: string): boolean {
    const result = this.runDocker(`exec -T accounts-app bin/rails runner "puts Identity::User.find_by(email: '${email}').verified?"`);
    return result === 'true';
  }

  static generateRandomEmail(): string {
    return `test-user-${Math.random().toString(36).substring(7)}@example.com`;
  }

  static getPasswordResetToken(email: string): string {
    return this.runDocker(`exec -T accounts-app bin/rails runner "puts Identity::User.find_by(email: '${email}').generate_token_for(:password_reset)"`);
  }

  static resetUserPasswordToDefault(email: string): void {
    this.runDocker(`exec -T accounts-app bin/rails runner "user = Identity::User.find_by(email: '${email}'); user.update!(password: 'Password123!456', password_confirmation: 'Password123!456')"`);
  }
}
