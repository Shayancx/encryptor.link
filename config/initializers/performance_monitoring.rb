# frozen_string_literal: true

if Rails.env.development? || Rails.env.test?
  ActiveSupport::Notifications.subscribe "sql.active_record" do |name, start, finish, id, payload|
    duration = (finish - start) * 1000
    if duration > 100 # Log slow queries over 100ms
      Rails.logger.warn "SLOW QUERY (#{duration.round(2)}ms): #{payload[:sql]}"
    end
  end

  ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
    duration = (finish - start) * 1000
    if duration > 500 # Log slow requests over 500ms
      Rails.logger.warn "SLOW REQUEST (#{duration.round(2)}ms): #{payload[:controller]}##{payload[:action]}"
    end
  end
end
