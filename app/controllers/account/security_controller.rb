class Account::SecurityController < Account::BaseController
  def show
    @user = Current.user
  end

  def update_password
    @user = Current.user

    if @user.authenticate(params[:current_password])
      if @user.update(password: params[:new_password], password_confirmation: params[:password_confirmation])
        redirect_to account_security_path, notice: "Password updated successfully"
      else
        flash.now[:alert] = @user.errors.full_messages.join(", ")
        render :show
      end
    else
      flash.now[:alert] = "Current password is incorrect"
      render :show
    end
  end
end
