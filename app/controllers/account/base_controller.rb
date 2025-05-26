class Account::BaseController < ApplicationController
  before_action :require_authentication

  private

  def require_authentication
    redirect_to new_session_path unless authenticated?
  end
end
