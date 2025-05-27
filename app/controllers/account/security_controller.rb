class Account::SecurityController < Account::BaseController
  before_action :require_reauthentication, except: [ :reauthenticate, :authenticate ]

  def show
    @user = Current.user
  end

  def reauthenticate
    # Show re-authentication form
  end

  def authenticate
    if Current.user.authenticate(params[:password])
      # Store encryption key and mark as re-authenticated
      Current.encryption_key = Current.user.derive_key_from_password(params[:password])
      session[:reauthenticated_at] = Time.current
      session[:encryption_key] = Current.encryption_key
      redirect_to account_security_path
    else
      flash.now[:alert] = "Incorrect password"
      render :reauthenticate
    end
  end

  def update_password
    @user = Current.user

    if @user.authenticate(params[:current_password])
      if params[:new_password] == params[:password_confirmation]
        if @user.update(password: params[:new_password])
          # Re-encrypt all user data with new password
          re_encrypt_user_data(params[:current_password], params[:new_password])
          redirect_to account_security_path, notice: "Password updated successfully"
        else
          flash.now[:alert] = "Password must be at least 6 characters"
          render :show
        end
      else
        flash.now[:alert] = "New password and confirmation don't match"
        render :show
      end
    else
      flash.now[:alert] = "Current password is incorrect"
      render :show
    end
  end

  private

  def require_reauthentication
    # Require re-authentication every 5 minutes for security settings
    if !session[:reauthenticated_at] || session[:reauthenticated_at] < 5.minutes.ago
      redirect_to reauthenticate_account_security_path
    end
  end

  def re_encrypt_user_data(old_password, new_password)
    old_key = Current.user.derive_key_from_password(old_password)
    new_key = Current.user.derive_key_from_password(new_password)

    # Re-encrypt all user message metadata
    Current.user.user_message_metadata.find_each do |metadata|
      metadata.decrypt_metadata(old_key)
      metadata.encrypt_metadata(new_key)
      metadata.save!
    end

    # Update current encryption key
    Current.encryption_key = new_key
    session[:encryption_key] = new_key
  rescue => e
    Rails.logger.error "Failed to re-encrypt user data: #{e.message}"
  end
end
