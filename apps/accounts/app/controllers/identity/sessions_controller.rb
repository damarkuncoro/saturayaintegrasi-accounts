module Identity
  class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[ new create ]
  before_action :redirect_if_authenticated, only: %i[ new create ]

  before_action :set_session, only: :destroy

  def index
    @sessions = System::Current.user.sessions.order(created_at: :desc)
  end

  def new
  end

  def create
    result = UseCases::Identity::Auth::Login.new.execute(
      email: params[:email],
      password: params[:password],
      tenant: System::Current.tenant,
      ip_address: request.ip,
      user_agent: request.user_agent,
      trusted_device_fingerprint: cookies.signed[trusted_device_cookie_name]
    )

    if result.success?
      user = result.value
      if result.meta[:status] == :mfa_required
        session[:otp_user_id] = user.id
        return redirect_to new_two_factor_challenge_path
      end

      @session = result.meta[:session]
      cookies.signed.permanent[auth_session_cookie_name] = session_cookie_options(@session.id)
      
      # Handle OAuth flow if return_to is present and is an authorize request
      if params[:return_to].present?
        safe_return_url = SatuRayaIdentityClient::Identity::RedirectValidator.safe_url(
          params[:return_to],
          fallback: after_authentication_url
        )
        
        if params[:return_to].include?("/oauth/authorize")
          redirect_to safe_return_url, allow_other_host: true
        else
          redirect_to safe_return_url, notice: "Signed in successfully"
        end
      else
        redirect_to after_authentication_url, notice: "Signed in successfully"
      end
    else
      redirect_to sign_in_path(email_hint: params[:email], return_to: params[:return_to]), alert: result.error
    end
  end

  def omniauth
    result = UseCases::Identity::Auth::LoginWithOauth.new.execute(
      auth: request.env["omniauth.auth"],
      tenant: require_current_tenant!,
      ip_address: request.ip,
      user_agent: request.user_agent
    )

    if result.success?
      user = result.value
      @session = result.meta[:session]
      cookies.signed.permanent[auth_session_cookie_name] = session_cookie_options(@session.id)
      redirect_to after_authentication_url, notice: "Signed in with #{request.env["omniauth.auth"].provider.titleize} successfully"
    else
      redirect_to sign_in_path, alert: result.error
    end
  end

  def destroy
    if @session
      UseCases::Identity::Auth::RevokeSession.new.execute(session: @session, reason: "user_logout")
      redirect_to sessions_path, notice: "That session has been logged out"
    else
      if (session_record = Identity::Session.find_by(id: cookies.signed[auth_session_cookie_name]))
        UseCases::Identity::Auth::RevokeSession.new.execute(session: session_record, reason: "user_logout")
      end
      terminate_session
      redirect_to root_path, notice: "Signed out successfully"
    end
  end

  private
    def set_session
      @session = System::Current.user.sessions.find(params[:id]) if params[:id].present?
    end
end

end
