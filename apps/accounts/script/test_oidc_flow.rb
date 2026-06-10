# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'jwt'

# This script simulates an OIDC client flow to verify the implementation.
# Usage: Run this script while the accounts server is running.
# Note: You need a valid client_id and client_secret from the database.

BASE_URL = ENV.fetch('ACCOUNTS_URL', 'http://localhost:3000')
CLIENT_ID = ENV['TEST_CLIENT_ID']
CLIENT_SECRET = ENV['TEST_CLIENT_SECRET']
AUTH_CODE = ENV['TEST_AUTH_CODE']

def test_oidc_flow
  puts "Testing OIDC Flow for #{BASE_URL}..."

  # 1. Discovery
  puts "\n1. Testing Discovery Endpoint..."
  uri = URI("#{BASE_URL}/.well-known/openid-configuration")
  response = Net::HTTP.get_response(uri)
  if response.is_a?(Net::HTTPSuccess)
    config = JSON.parse(response.body)
    puts "✅ Discovery successful: #{config['issuer']}"
  else
    puts "❌ Discovery failed: #{response.code} #{response.message}"
    return
  end

  # 2. JWKS
  puts "\n2. Testing JWKS Endpoint..."
  uri = URI("#{BASE_URL}/.well-known/jwks.json")
  response = Net::HTTP.get_response(uri)
  if response.is_a?(Net::HTTPSuccess)
    puts "✅ JWKS successful"
  else
    puts "❌ JWKS failed: #{response.code} #{response.message}"
  end

  # 3. Token Exchange (Simulated)
  if AUTH_CODE && CLIENT_ID && CLIENT_SECRET
    puts "\n3. Testing Token Exchange..."
    uri = URI("#{BASE_URL}/oauth/token")
    res = Net::HTTP.post_form(uri, {
      'client_id' => CLIENT_ID,
      'client_secret' => CLIENT_SECRET,
      'code' => AUTH_CODE,
      'grant_type' => 'authorization_code'
    })

    if res.is_a?(Net::HTTPSuccess)
      tokens = JSON.parse(res.body)
      puts "✅ Token exchange successful"
      access_token = tokens['access_token']

      # 4. Userinfo
      puts "\n4. Testing Userinfo..."
      uri = URI("#{BASE_URL}/oauth/userinfo")
      req = Net::HTTP::Get.new(uri)
      req['Authorization'] = "Bearer #{access_token}"
      user_res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

      if user_res.is_a?(Net::HTTPSuccess)
        user = JSON.parse(user_res.body)
        puts "✅ Userinfo successful: #{user['email']}"
      else
        puts "❌ Userinfo failed: #{user_res.code} #{user_res.message}"
      end
    else
      puts "❌ Token exchange failed: #{res.code} #{res.message}"
      puts res.body
    end
  else
    puts "\n3. Skipping Token Exchange (needs AUTH_CODE, CLIENT_ID, CLIENT_SECRET)"
  end
end

test_oidc_flow
