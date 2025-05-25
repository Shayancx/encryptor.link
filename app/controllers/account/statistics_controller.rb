class Account::StatisticsController < Account::BaseController
  def show
    @stats = calculate_user_statistics
  end

  private

  def calculate_user_statistics
    messages = Current.user.user_message_metadata

    # Calculate stats safely with fallbacks
    total_messages = messages.count
    active_messages = messages.where('original_expiry > ?', Time.current).count
    expired_messages = total_messages - active_messages
    total_file_size = messages.sum(:file_size) || 0
    total_views = messages.sum(:accessed_count) || 0

    # Calculate average views per message
    average_views = total_messages > 0 ? (total_views.to_f / total_messages).round(2) : 0

    # Group by type with fallback
    messages_by_type = {}
    begin
      messages_by_type = messages.group(:message_type).count
    rescue
      messages_by_type = { 'text' => total_messages }
    end

    # Group by month with fallback
    messages_by_month = {}
    begin
      messages_by_month = messages.group_by_month(:created_at, last: 6).count
    rescue
      messages_by_month = { Time.current.beginning_of_month => total_messages }
    end

    {
      total_messages: total_messages,
      active_messages: active_messages,
      expired_messages: expired_messages,
      total_file_size: total_file_size,
      messages_by_type: messages_by_type,
      messages_by_month: messages_by_month,
      total_views: total_views,
      average_views_per_message: average_views
    }
  end
end
