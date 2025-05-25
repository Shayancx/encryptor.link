class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create show ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def show
    # If user is already authenticated, redirect to account dashboard
    if authenticated?
      redirect_to account_dashboard_path
    else
      # If not authenticated, redirect to login form
      redirect_to new_session_path
    end
  end

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
