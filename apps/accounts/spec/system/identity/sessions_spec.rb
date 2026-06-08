require "rails_helper"

RSpec.describe "User Sessions", type: :system do
  let!(:tenant) { create(:tenant, domain: "company.satu-raya.test") }
  let(:user) { create(:user, tenant: tenant, verified: true) }

  before do
    # Ensure there's a clean slate before each test run
    Capybara.reset_sessions!
    Capybara.app_host = "http://company.satu-raya.test"
  end

  after do
    Capybara.app_host = nil
  end

  it "logs in successfully and redirects to dashboard" do
    visit sign_in_path

    # Fill in the form fields using Indonesian labels
    fill_in "Alamat Email", with: user.email
    fill_in "Kata Sandi", with: "Password123!456" # default factory password
    click_button "Masuk Sekarang"

    # Verify that the user is redirected to the Dashboard
    expect(page).to have_current_path("/dashboard")
    expect(page).to have_content("Signed in successfully")
    expect(page).to have_content(user.first_name)
  end

  it "shows validation error with incorrect credentials" do
    visit sign_in_path

    fill_in "Alamat Email", with: user.email
    fill_in "Kata Sandi", with: "wrong_password_123"
    click_button "Masuk Sekarang"

    # Verify that the user stays on the sign-in page and shows an alert banner
    expect(page).to have_current_path(sign_in_path(email_hint: user.email))
    expect(page).to have_content("Email atau kata sandi salah.")
  end

  it "logs out successfully via the profile menu dropdown" do
    # First log in
    visit sign_in_path
    fill_in "Alamat Email", with: user.email
    fill_in "Kata Sandi", with: "Password123!456"
    click_button "Masuk Sekarang"

    expect(page).to have_current_path("/dashboard")

    # Click the "Keluar" (Logout) button directly on the page
    click_button "Keluar"

    # Should redirect to root path (which resolves to sign_in_path since user is unauthenticated)
    expect(page).to have_current_path(sign_in_path)
    expect(page).to have_content("Signed out successfully")
  end
end
