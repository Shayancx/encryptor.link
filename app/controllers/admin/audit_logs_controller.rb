class Admin::AuditLogsController < ApplicationController
  def index
    @logs = AuditLog.order(created_at: :desc)
                    .limit(1000)
                    .select(:event_type, :endpoint, :ip_address, :severity, :created_at)

    render json: @logs
  end
end
