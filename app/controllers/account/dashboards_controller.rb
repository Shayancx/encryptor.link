class Account::DashboardsController < Account::BaseController
  def show
    user_messages = Current.user.user_message_metadata

    @recent_messages = user_messages.order(created_at: :desc).limit(5)

    # Decrypt message labels if we have encryption key
    if Current.encryption_key.present?
      @recent_messages.each do |message|
        message.decrypt_metadata(Current.encryption_key)
      end
    end

    @total_messages = user_messages.count
    @active_messages = user_messages.where("original_expiry IS NULL OR original_expiry > ?", Time.current).count
    @expired_messages = user_messages.where("original_expiry IS NOT NULL AND original_expiry <= ?", Time.current).count

    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: "authenticated",
          user_id: Current.user.id,
          email: Current.user.email_address,
          stats: {
            total_messages: @total_messages,
            active_messages: @active_messages,
            expired_messages: @expired_messages
          }
        }
      }
    end
  end
end
