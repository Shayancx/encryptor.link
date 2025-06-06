module AdminAuthenticable
  extend ActiveSupport::Concern

  included do
    before_action :require_admin_authentication
    before_action :require_audit_permissions, only: [ :index, :show ]
  end

  private

  def require_admin_authentication
    unless current_admin_user
      AuditService.log(
        event_type: AuditService::EVENTS[:unauthorized_admin_access],
        request: request,
        metadata: { attempted_path: request.path }
      )
      redirect_to admin_login_path
    end
  end

  def require_audit_permissions
    unless current_admin_user&.can_view_audit_logs?
      AuditService.log(
        event_type: AuditService::EVENTS[:unauthorized_audit_access],
        request: request,
        metadata: {
          admin_email: current_admin_user&.email,
          admin_role: current_admin_user&.role
        }
      )
      render json: { error: "Insufficient permissions" }, status: :forbidden
    end
  end

  def current_admin_user
    @current_admin_user ||= AdminUser.active.find_by(id: session[:admin_user_id])
  end
end
