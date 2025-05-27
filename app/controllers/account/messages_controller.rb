class Account::MessagesController < Account::BaseController
  def index
    page = (params[:page] || 1).to_i
    per_page = 20

    @messages = Current.user.user_message_metadata
                           .order(created_at: :desc)
                           .limit(per_page)
                           .offset((page - 1) * per_page)

    # Decrypt message metadata if we have encryption key
    if Current.encryption_key.present?
      @messages.each do |message|
        message.decrypt_metadata(Current.encryption_key)
      end
    end

    @total_count = Current.user.user_message_metadata.count
    @current_page = page
    @total_pages = (@total_count.to_f / per_page).ceil
  end

  def show
    @message = Current.user.user_message_metadata.find(params[:id])

    # Decrypt metadata
    if Current.encryption_key.present?
      @message.decrypt_metadata(Current.encryption_key)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to account_messages_path, alert: "Message not found"
  end

  def destroy
    @message = Current.user.user_message_metadata.find(params[:id])
    @message.destroy
    redirect_to account_messages_path, notice: "Message removed from history"
  rescue ActiveRecord::RecordNotFound
    redirect_to account_messages_path, alert: "Message not found"
  end
end
