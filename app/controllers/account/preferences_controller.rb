class Account::PreferencesController < Account::BaseController
  def show
    @user_preference = Current.user.user_preference || Current.user.build_user_preference
  end

  def update
    @user_preference = Current.user.user_preference || Current.user.build_user_preference

    if @user_preference.update(preference_params)
      redirect_to account_preferences_path, notice: "Preferences updated successfully"
    else
      render :show
    end
  end

  private

  def preference_params
    params.require(:user_preference).permit(:default_ttl, :default_views, :theme_preference)
  end
end
