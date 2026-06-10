# frozen_string_literal: true

module AuthenticationHelpers
  def login_as(user)
    expected_path = dashboard_path_for(user)

    3.times do
      visit login_path

      # If we are already logged in as the correct user and redirected to the expected path
      return if page.has_current_path?(expected_path, wait: 1)

      # If we are logged in as a different user, or the login page redirects us away,
      # reset the session so we get a clean slate.
      if page.has_no_field?("Alamat Email")
        Capybara.reset_sessions!
        next
      end

      fill_in "Alamat Email", with: user.email
      fill_in "Kata Sandi", with: "Password123!456" # Factory default
      click_button "Masuk Sekarang"

      return if page.has_current_path?(expected_path, wait: 3)
    end

    expect(page).to have_current_path(expected_path)
  end

  def dashboard_path_for(user)
    return admin_dashboard_path if user.admin?
    "/dashboard"
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :system
end
