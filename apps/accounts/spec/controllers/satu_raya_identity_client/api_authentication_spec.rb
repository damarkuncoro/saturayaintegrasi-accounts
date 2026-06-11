require "rails_helper"

RSpec.describe SatuRayaIdentityClient::ApiAuthentication, type: :controller do
  controller(ActionController::API) do
    include SatuRayaIdentityClient::ApiAuthentication

    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def index
      render json: { ok: true }
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }

    SatuRayaIdentityClient.configure do |config|
      config.jwt_secret = "test-secret"
      config.jwt_algorithm = "HS256"
    end
  end

  after do
    SatuRayaIdentityClient.configuration = nil
    System::Current.reset
  end

  it "returns a generic error for invalid JWTs without leaking decoder details" do
    request.headers["Authorization"] = "Bearer invalid-token"

    get :index

    json = JSON.parse(response.body)
    expect(response).to have_http_status(:unauthorized)
    expect(json["message"]).to eq("Invalid or expired token")
    expect(json["message"]).not_to include("Not enough or too many segments")
  end
end
