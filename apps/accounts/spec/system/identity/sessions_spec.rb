require "rails_helper"

RSpec.describe "User Sessions", type: :system do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant, verified: true) }

  before do
    # Ensure there's a clean slate before each test run
    Capybara.reset_sessions!
  end

  it "logs in successfully and redirects to dashboard" do
    visit sign_in_path

    # Fill in the form fields using Indonesian labels
    fill_in "Alamat Email", with: user.email
    fill_in "Kata Sandi", with: "Password123!456" # default factory password
    click_button "Masuk Sekarang"

    # Verify that the user is redirected to the Mock Dashboard
    expect(page).to have_current_path("/mock_dashboard")
    expect(page).to have_content("Mock Dashboard")
    expect(page).to have_content("Welcome to the test dashboard!")
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

    expect(page).to have_current_path("/mock_dashboard")

    # Reveal the profile menu dropdown using JavaScript to prevent event listener race conditions
    page.execute_script("document.getElementById('profile-panel').classList.remove('hidden')")

    # Click the "Keluar" (Logout) button inside the dropdown panel
    click_button "Keluar"

    # Should redirect to root path
    expect(page).to have_current_path("/")
    expect(page).to have_content("Signed out successfully")
  end
end
