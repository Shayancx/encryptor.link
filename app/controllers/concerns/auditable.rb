module Auditable
  extend ActiveSupport::Concern

  included do
    before_action { @request_start_time = Time.current }
    after_action :audit_request
  end

  private

  def audit_request
    return if request.path == "/health"

    AuditService.log(
      event_type: "#{controller_name}_#{action_name}",
      request: request,
      payload_id: params[:id],
      metadata: {
        response_status: response.status,
        processing_time: Time.current - @request_start_time
      }
    )
  end
end
