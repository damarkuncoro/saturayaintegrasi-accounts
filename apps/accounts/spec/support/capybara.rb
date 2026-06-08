require 'capybara/rspec'
require 'playwright'

Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: true,
    args: %w[
      --no-sandbox
      --disable-dev-shm-usage
      --disable-gpu
    ]
  )
end

Capybara.javascript_driver = :playwright

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright
  end
end
