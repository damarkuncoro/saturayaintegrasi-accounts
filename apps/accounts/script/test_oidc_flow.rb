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
REFRESH_TOKEN = ENV['TEST_REFRESH_TOKEN']

def request_for(uri)
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    yield http
  end
end

def parse_json(response)
  JSON.parse(response.body)
rescue JSON::ParserError
  {}
end

def basic_auth!(request)
  request.basic_auth(CLIENT_ID, CLIENT_SECRET) if CLIENT_ID && CLIENT_SECRET
end

def post_form(path, form)
  uri = URI("#{BASE_URL}#{path}")
  request = Net::HTTP::Post.new(uri)
  basic_auth!(request)
  request.set_form_data(form)
  request_for(uri) { |http| http.request(request) }
end

def get_json(path, bearer_token: nil)
  uri = URI("#{BASE_URL}#{path}")
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{bearer_token}" if bearer_token
  request_for(uri) { |http| http.request(request) }
end

def test_oidc_flow
  puts "Testing OIDC Flow for #{BASE_URL}..."

  # 1. Discovery
  puts "\n1. Testing Discovery Endpoint..."
  response = get_json('/.well-known/openid-configuration')
  if response.is_a?(Net::HTTPSuccess)
    config = parse_json(response)
    puts "✅ Discovery successful: #{config['issuer']}"
  else
    puts "❌ Discovery failed: #{response.code} #{response.message}"
    return
  end

  # 2. JWKS
  puts "\n2. Testing JWKS Endpoint..."
  response = get_json('/.well-known/jwks.json')
  if response.is_a?(Net::HTTPSuccess)
    puts "✅ JWKS successful"
  else
    puts "❌ JWKS failed: #{response.code} #{response.message}"
  end

  access_token = nil
  refresh_token = REFRESH_TOKEN

  # 3. Token Exchange
  if AUTH_CODE && CLIENT_ID && CLIENT_SECRET
    puts "\n3. Testing Token Exchange..."
    res = post_form('/oauth/token', {
      'client_id' => CLIENT_ID,
      'client_secret' => CLIENT_SECRET,
      'code' => AUTH_CODE,
      'grant_type' => 'authorization_code'
    })

    if res.is_a?(Net::HTTPSuccess)
      tokens = parse_json(res)
      puts "✅ Token exchange successful"
      access_token = tokens['access_token']
      refresh_token ||= tokens['refresh_token']
    else
      puts "❌ Token exchange failed: #{res.code} #{res.message}"
      puts res.body
    end
  else
    puts "\n3. Skipping Token Exchange (needs AUTH_CODE, CLIENT_ID, CLIENT_SECRET)"
  end

  if access_token
    # 4. Userinfo
    puts "\n4. Testing Userinfo..."
    user_res = get_json('/oauth/userinfo', bearer_token: access_token)

    if user_res.is_a?(Net::HTTPSuccess)
      user = parse_json(user_res)
      puts "✅ Userinfo successful: #{user['email'] || user['sub']}"
    else
      puts "❌ Userinfo failed: #{user_res.code} #{user_res.message}"
    end

    # 5. Introspection
    puts "\n5. Testing Token Introspection..."
    introspect_res = post_form('/oauth/introspect', { 'token' => access_token })

    if introspect_res.is_a?(Net::HTTPSuccess)
      introspection = parse_json(introspect_res)
      puts "✅ Introspection successful: active=#{introspection['active']}"
    else
      puts "❌ Introspection failed: #{introspect_res.code} #{introspect_res.message}"
    end
  else
    puts "\n4-5. Skipping Userinfo and Introspection (needs access token)"
  end

  # 6. Refresh Token Rotation
  if refresh_token && CLIENT_ID && CLIENT_SECRET
    puts "\n6. Testing Refresh Token Rotation..."
    refresh_res = post_form('/oauth/token', {
      'client_id' => CLIENT_ID,
      'client_secret' => CLIENT_SECRET,
      'grant_type' => 'refresh_token',
      'refresh_token' => refresh_token
    })

    if refresh_res.is_a?(Net::HTTPSuccess)
      refreshed = parse_json(refresh_res)
      access_token = refreshed['access_token'] || access_token
      refresh_token = refreshed['refresh_token'] || refresh_token
      puts "✅ Refresh token rotation successful"
    else
      puts "❌ Refresh token rotation failed: #{refresh_res.code} #{refresh_res.message}"
    end
  else
    puts "\n6. Skipping Refresh Token Rotation (needs refresh token, CLIENT_ID, CLIENT_SECRET)"
  end

  # 7. Revocation
  if refresh_token && CLIENT_ID && CLIENT_SECRET
    puts "\n7. Testing Token Revocation..."
    revoke_res = post_form('/oauth/revoke', { 'token' => refresh_token })

    if revoke_res.is_a?(Net::HTTPSuccess)
      puts "✅ Revocation successful"
    else
      puts "❌ Revocation failed: #{revoke_res.code} #{revoke_res.message}"
    end
  else
    puts "\n7. Skipping Revocation (needs refresh token, CLIENT_ID, CLIENT_SECRET)"
  end
end

test_oidc_flow
