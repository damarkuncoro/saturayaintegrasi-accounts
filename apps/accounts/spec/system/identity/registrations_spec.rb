require "rails_helper"

RSpec.describe "User Registrations", type: :system do
  let!(:tenant) { create(:tenant, domain: "company.satu-raya.test") }

  before do
    Capybara.reset_sessions!
    Capybara.app_host = "http://company.satu-raya.test"
  end

  after do
    Capybara.app_host = nil
  end

  it "registers a new account successfully and redirects to dashboard" do
    visit sign_up_path

    # Fill in the form fields using exact Rails field names
    fill_in "user[first_name]", with: "Lazaro"
    fill_in "user[last_name]", with: "Nixon"
    fill_in "user[email]", with: "lazaronixon@hey.com"
    fill_in "user[phone]", with: "08123456789"

    fill_in "user[password]", with: "Secret1*3*5*"
    fill_in "user[password_confirmation]", with: "Secret1*3*5*"

    click_button "Daftar Sekarang"

    # Verify that the user is redirected to the Dashboard
    expect(page).to have_current_path("/dashboard")
    expect(page).to have_content("Welcome! You have signed up successfully")
  end

  it "shows validation errors when invalid parameters are supplied" do
    visit sign_up_path

    # Disable HTML5 validation to allow submission to server
    page.execute_script("document.querySelector('form').setAttribute('novalidate', 'novalidate')")

    # Fill required fields with invalid or short values
    fill_in "user[first_name]", with: "L"
    fill_in "user[last_name]", with: "N"
    fill_in "user[email]", with: "not_a_valid_email"
    fill_in "user[phone]", with: "12345"

    fill_in "user[password]", with: "123"
    fill_in "user[password_confirmation]", with: "wrong"

    click_button "Daftar Sekarang"

    # Verify that the user stays on the sign-up page and error banner is displayed
    expect(page).to have_content("Email tidak valid")
    expect(page).to have_content("Password confirmation tidak cocok dengan kata sandi")
  end
end
