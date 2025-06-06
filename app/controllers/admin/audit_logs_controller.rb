class Admin::AuditLogsController < ApplicationController
  include AdminAuthenticable

  def index
    @audit_logs = filtered_audit_logs
                   .includes(:payload)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(params[:per_page] || 50)

    respond_to do |format|
      format.html
      format.json { render json: audit_logs_json }
      format.csv { send_csv_export }
    end
  end

  def show
    @audit_log = AuditLog.find(params[:id])

    AuditService.log(
      event_type: AuditService::EVENTS[:audit_log_viewed],
      request: request,
      metadata: {
        viewed_log_id: @audit_log.id,
        admin_email: current_admin_user.email
      }
    )

    render json: @audit_log.as_json(include_metadata: true)
  end

  def export
    authorize_export!

    ExportAuditLogsJob.perform_later(
      current_admin_user.id,
      export_params.to_h,
      request.remote_ip
    )

    render json: { message: "Export started. You will receive an email when complete." }
  end

  private

  def filtered_audit_logs
    logs = AuditLog.all

    if params[:start_date].present? && params[:end_date].present?
      logs = logs.where(created_at: parse_date(params[:start_date])..parse_date(params[:end_date]))
    end

    if params[:event_types].present?
      event_types = params[:event_types].split(",").map(&:strip)
      logs = logs.where(event_type: event_types)
    end

    if params[:severity].present?
      logs = logs.where(severity: params[:severity])
    end

    if params[:ip_address].present?
      logs = logs.where(ip_address: params[:ip_address])
    end

    if params[:payload_id].present?
      logs = logs.where(payload_id: params[:payload_id])
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      logs = logs.where(
        "metadata::text ILIKE ? OR user_agent ILIKE ? OR endpoint ILIKE ?",
        search_term, search_term, search_term
      )
    end

    logs
  end

  def audit_logs_json
    {
      audit_logs: @audit_logs.map do |log|
        log.as_json.merge(
          formatted_created_at: log.created_at.strftime("%Y-%m-%d %H:%M:%S UTC"),
          metadata_summary: summarize_metadata(log.metadata)
        )
      end,
      pagination: {
        current_page: @audit_logs.current_page,
        total_pages: @audit_logs.total_pages,
        total_count: @audit_logs.total_count
      },
      filters: current_filters
    }
  end

  def authorize_export!
    unless current_admin_user.can_export_audit_logs?
      AuditService.log(
        event_type: AuditService::EVENTS[:unauthorized_audit_export],
        request: request,
        metadata: { admin_email: current_admin_user.email }
      )
      raise StandardError, "Export not authorized"
    end
  end

  def export_params
    params.permit(:start_date, :end_date, :event_types, :severity, :ip_address, :payload_id, :search)
  end

  def parse_date(date_str)
    Time.zone.parse(date_str)
  rescue
    nil
  end

  def summarize_metadata(metadata)
    metadata.to_s.truncate(100)
  end

  def current_filters
    export_params.to_h
  end

  def send_csv_export
    headers["Content-Disposition"] = "attachment; filename=audit_logs.csv"
    render csv: @audit_logs.to_csv
  end
end
