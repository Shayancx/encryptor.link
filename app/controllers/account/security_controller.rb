class Account::SecurityController < Account::BaseController
  def show
    @user = Current.user
  end

  def update_password
    @user = Current.user

    if @user.authenticate(params[:current_password])
      if params[:new_password] == params[:password_confirmation]
        if @user.update(password: params[:new_password])
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
end
