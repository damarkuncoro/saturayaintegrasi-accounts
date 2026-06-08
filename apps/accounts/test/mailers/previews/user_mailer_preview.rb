# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def password_reset
    user = Identity::User.first || mock_user
    Identity::UserMailer.with(user: user).password_reset
  end

  def email_verification
    user = Identity::User.first || mock_user
    Identity::UserMailer.with(user: user).email_verification
  end

  private

  def mock_user
    tenant = System::Tenant.first || System::Tenant.create!(name: "Demo", slug: "demo")
    Identity::User.new(
      tenant: tenant,
      email: "worker@example.com",
      first_name: "John",
      last_name: "Doe",
      role: "worker",
      username: "worker_john"
    )
  end
end
