module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      if cookies.signed[:session_id] && (session = Session.find_by(id: cookies.signed[:session_id]))
        # Store the encryption key if available
        if session[:encryption_key].present?
          Current.encryption_key = session[:encryption_key]
        end
        session
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |new_session|
        Current.session = new_session
        Current.encryption_key = user.encryption_key

        # Store encryption key in session for this request
        session[:encryption_key] = user.encryption_key if user.encryption_key

        cookies.signed.permanent[:session_id] = { value: new_session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      Current.encryption_key = nil
      session.delete(:encryption_key)
      cookies.delete(:session_id)
    end
end
