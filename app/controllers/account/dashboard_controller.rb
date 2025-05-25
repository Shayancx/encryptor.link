class Account::DashboardController < Account::BaseController
  def show
    @recent_messages = Current.user.user_message_metadata
                                  .recent
                                  .limit(5)
    @total_messages = Current.user.user_message_metadata.count
    @active_messages = Current.user.user_message_metadata.active.count
    @expired_messages = Current.user.user_message_metadata.expired.count

    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: 'authenticated',
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
