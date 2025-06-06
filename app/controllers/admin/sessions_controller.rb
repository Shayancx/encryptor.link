class Admin::SessionsController < ApplicationController
  def new
  end

  def create
    admin = AdminUser.active.find_by(email: params[:email])

    if admin&.authenticate(params[:password])
      session[:admin_user_id] = admin.id
      AuditService.log(
        event_type: AuditService::EVENTS[:admin_login_success],
        request: request,
        metadata: { admin_email: admin.email, admin_role: admin.role }
      )
      redirect_to admin_audit_logs_path
    else
      AuditService.log(
        event_type: AuditService::EVENTS[:admin_login_failed],
        request: request,
        metadata: { attempted_email: params[:email] }
      )
      flash[:error] = 'Invalid credentials'
      render :new
    end
  end

  def destroy
    admin_id = session[:admin_user_id]
    admin = AdminUser.find_by(id: admin_id)

    AuditService.log(
      event_type: AuditService::EVENTS[:admin_logout],
      request: request,
      metadata: { admin_email: admin&.email }
    )

    session.delete(:admin_user_id)
    redirect_to admin_login_path
  end
end
