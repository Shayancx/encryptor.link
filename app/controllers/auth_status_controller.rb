class AuthStatusController < ApplicationController
  allow_unauthenticated_access only: [:check]

  def check
    if authenticated?
      render json: {
        authenticated: true,
        user_id: Current.user&.id,
        email: Current.user&.email_address
      }
    else
      render json: { authenticated: false }
    end
  end
end
