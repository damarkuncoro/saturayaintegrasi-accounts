require "rails_helper"

RSpec.describe "User Registrations", type: :system do
  let!(:tenant) { create(:tenant) }

  before do
    Capybara.reset_sessions!
  end

  it "registers a new worker account successfully and redirects to dashboard" do
    visit sign_up_path

    # Fill in the form fields using exact Rails field names
    fill_in "user[first_name]", with: "Lazaro"
    fill_in "user[last_name]", with: "Nixon"
    fill_in "user[email]", with: "lazaronixon@hey.com"
    fill_in "user[phone]", with: "08123456789"
    
    # Select the worker role from the dropdown
    select "Saya sedang mencari kerja (Pekerja)", from: "user[role]"

    fill_in "user[password]", with: "Secret1*3*5*"
    fill_in "user[password_confirmation]", with: "Secret1*3*5*"

    click_button "Daftar Sekarang"

    # Verify that the user is redirected to the Mock Dashboard
    expect(page).to have_current_path("/mock_dashboard")
    expect(page).to have_content("Mock Dashboard")
    expect(page).to have_content("Welcome! You have signed up successfully")
  end

  it "shows validation errors when invalid parameters are supplied" do
    visit sign_up_path

    # Fill required fields with invalid or short values to bypass HTML5 client-side validation
    # so the form actually submits to the server.
    fill_in "user[first_name]", with: "L"
    fill_in "user[last_name]", with: "N"
    fill_in "user[email]", with: "not_a_valid_email"
    fill_in "user[phone]", with: "12345"

    fill_in "user[password]", with: "123"
    fill_in "user[password_confirmation]", with: "wrong"

    click_button "Daftar Sekarang"

    # Verify that the user stays on the sign-up page and error banner is displayed
    expect(page).to have_content(/kesalahan/i)
    expect(page).to have_content("Email tidak valid")
  end
end
