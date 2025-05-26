class Account::StatisticsController < Account::BaseController
  def show
    messages = Current.user.user_message_metadata

    @stats = {
      total_messages: messages.count,
      active_messages: messages.where('original_expiry IS NULL OR original_expiry > ?', Time.current).count,
      expired_messages: messages.where('original_expiry IS NOT NULL AND original_expiry <= ?', Time.current).count,
      messages_by_type: {}
    }

    # Group by type safely
    type_counts = messages.group(:message_type).count
    @stats[:messages_by_type] = type_counts.presence || { 'text' => 0 }
  end
end
