require 'rails_helper'

# We define a temporary controller to test redirection logic in ApplicationController
class TestRedirectsController < ApplicationController
  skip_before_action :require_current_tenant!, raise: false
  allow_unauthenticated_access only: :redirect_test

  def redirect_test
    redirect_to params[:to]
  end
end

RSpec.describe 'Redirects Security', type: :request do
  before :all do
    # Add a mock route for testing redirection
    Rails.application.routes.draw do
      get 'redirect_test' => 'test_redirects#redirect_test'
      # Keep standard sign-in route just in case
      get 'login' => 'identity/sessions#new', as: :sign_in
    end
  end

  after :all do
    # Restore normal routes
    Rails.application.reload_routes!
  end

  let(:domain) { SatuRayaIdentityClient::Identity::BrandConfig.app_domain }

  describe 'GET /redirect_test' do
    context 'with valid domain' do
      it 'allows redirection to the exact configured domain' do
        get '/redirect_test', params: { to: "https://#{domain}/dashboard" }
        expect(response).to redirect_to("https://#{domain}/dashboard")
      end

      it 'allows redirection to a subdomain of the configured domain' do
        get '/redirect_test', params: { to: "https://jobs.#{domain}/dashboard" }
        expect(response).to redirect_to("https://jobs.#{domain}/dashboard")
      end

      it 'allows redirection to nested subdomains' do
        get '/redirect_test', params: { to: "https://deep.sub.#{domain}/path" }
        expect(response).to redirect_to("https://deep.sub.#{domain}/path")
      end
    end

    context 'with malicious open redirect attempts' do
      it 'blocks redirection to domains with matching suffix but wrong prefix' do
        expect {
          get '/redirect_test', params: { to: "https://attacker-#{domain}/dashboard" }
        }.to raise_error(StandardError, /allow_other_host/)
      end

      it 'blocks redirection to external domains containing the domain in query params' do
        expect {
          get '/redirect_test', params: { to: "https://attacker.com/dashboard?domain=#{domain}" }
        }.to raise_error(StandardError, /allow_other_host/)
      end

      it 'blocks redirection to external domains containing the domain in the path' do
        expect {
          get '/redirect_test', params: { to: "https://attacker.com/#{domain}" }
        }.to raise_error(StandardError, /allow_other_host/)
      end

      it 'blocks redirection to malformed URIs' do
        expect {
          get '/redirect_test', params: { to: "https://attacker.com\\#{domain}" }
        }.to raise_error(StandardError, /allow_other_host/)
      end
    end
  end
end
