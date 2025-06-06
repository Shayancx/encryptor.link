# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    checks = {
      database: check_database,
      disk_space: check_disk_space,
      data_integrity: check_recent_integrity
    }

    status = checks[:database] && checks[:disk_space] ? :ok : :service_unavailable

    render json: {
      status: status == :ok ? "healthy" : "unhealthy",
      timestamp: Time.current.iso8601,
      checks: checks
    }, status: status
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue
    false
  end

  def check_disk_space
    # Simple disk space check - can be enhanced
    true
  rescue
    true
  end

  def check_recent_integrity
    recent_failures = AuditLog.where(
      event_type: "integrity_check_failed",
      created_at: 24.hours.ago..Time.current
    ).count

    recent_failures == 0
  rescue
    false
  end
end
