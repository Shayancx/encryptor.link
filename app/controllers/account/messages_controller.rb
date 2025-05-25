class Account::MessagesController < Account::BaseController
  def index
    @messages = Current.user.user_message_metadata
                           .recent
                           .page(params[:page])
  end

  def show
    @message = Current.user.user_message_metadata.find(params[:id])
    @message.increment_access_count!
  end

  def update
    @message = Current.user.user_message_metadata.find(params[:id])

    if @message.update(message_params)
      redirect_to account_messages_path, notice: "Message updated successfully"
    else
      render :show
    end
  end

  def destroy
    @message = Current.user.user_message_metadata.find(params[:id])
    @message.destroy
    redirect_to account_messages_path, notice: "Message removed from history"
  end

  private

  def message_params
    params.require(:user_message_metadata).permit(:encrypted_label)
  end
end
