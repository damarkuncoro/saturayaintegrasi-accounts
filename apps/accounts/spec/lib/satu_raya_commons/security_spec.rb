require "rails_helper"

RSpec.describe "SatuRayaCommons::Security" do
  let(:secret) { "my_secure_shared_secret_key_123" }
  let(:payload) { { user_id: "user-123", email: "test@example.com" }.to_json }

  describe "HmacSigner" do
    it "signs payload correctly and generates a valid hex signature" do
      signature = SatuRayaCommons::Security::HmacSigner.sign(payload, secret)
      expect(signature).to be_a(String)
      expect(signature.length).to eq(64) # SHA256 hex length
    end

    it "verifies valid signatures correctly" do
      signature = SatuRayaCommons::Security::HmacSigner.sign(payload, secret)
      expect(SatuRayaCommons::Security::HmacSigner.verify?(payload, signature, secret)).to be true
    end

    it "fails verification for invalid signature or modified payload" do
      signature = SatuRayaCommons::Security::HmacSigner.sign(payload, secret)
      expect(SatuRayaCommons::Security::HmacSigner.verify?("modified payload", signature, secret)).to be false
      expect(SatuRayaCommons::Security::HmacSigner.verify?(payload, "wrong_sig", secret)).to be false
    end
  end

  describe "JwtCodec" do
    let(:payload_hash) { { "user_id" => "user-123", "role" => "user" } }

    it "encodes payload into a valid signed JWT" do
      token = SatuRayaCommons::Security::JwtCodec.encode(payload_hash, secret)
      expect(token).to be_a(String)
      expect(token.split(".").length).to eq(3)
    end

    it "decodes a valid JWT back into the payload" do
      token = SatuRayaCommons::Security::JwtCodec.encode(payload_hash, secret)
      decoded = SatuRayaCommons::Security::JwtCodec.decode(token, secret)
      expect(decoded).to be_present
      expect(decoded["user_id"]).to eq("user-123")
      expect(decoded["role"]).to eq("user")
      expect(decoded["exp"]).to be_present
    end

    it "returns nil for invalid token or wrong secret" do
      token = SatuRayaCommons::Security::JwtCodec.encode(payload_hash, secret)
      expect(SatuRayaCommons::Security::JwtCodec.decode(token, "wrong_secret_key")).to be_nil
      expect(SatuRayaCommons::Security::JwtCodec.decode("invalid.token.string", secret)).to be_nil
    end

    it "returns nil for expired tokens" do
      token = SatuRayaCommons::Security::JwtCodec.encode(payload_hash, secret, -1.hour)
      expect(SatuRayaCommons::Security::JwtCodec.decode(token, secret)).to be_nil
    end
  end
end
