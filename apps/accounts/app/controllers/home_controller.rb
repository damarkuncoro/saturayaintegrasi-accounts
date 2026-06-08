class HomeController < ApplicationController
  skip_before_action :require_authentication, only: [ :index ]

  def index
    if System::Current.user
      redirect_to identity_dashboard_path
    else
      redirect_to sign_in_path
    end
  end

  def dashboard
    @user = System::Current.user
    @sessions = @user.sessions.order(created_at: :desc).limit(5)
    render layout: "application"
  end

  def mock_dashboard
  end
end
