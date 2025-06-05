# frozen_string_literal: true

class DecryptionsController < ApplicationController
  before_action :check_session_flags, only: :show

  def show
    @payload_info = decryption_service.payload_info
    render :show
  end

  def data
    existing_payload = EncryptedPayload.find_by(id: params[:id])
    response_data = decryption_service.retrieve_data

    if response_data
      response_data[:burn_after_reading] = existing_payload&.burn_after_reading || false
      render json: response_data
    else
      session[:payload_expired] = true
      head :gone
    end
  end

  def info
    payload = EncryptedPayload.find_by(id: params[:id])

    if payload.nil?
      render json: {
        exists: false,
        message: "This link does not exist"
      }, status: :not_found
      return
    end

    time_remaining = if payload.expired?
      "Expired"
    else
      distance_of_time_in_words(Time.current, payload.expires_at)
    end

    total_size = payload.ciphertext.bytesize
    total_size += payload.encrypted_files.sum(:file_size) if payload.encrypted_files.any?

    render json: {
      exists: true,
      created_at: payload.created_at.iso8601,
      expires_at: payload.expires_at.iso8601,
      expired: payload.expired?,
      time_remaining: time_remaining,
      remaining_views: payload.remaining_views,
      burn_after_reading: payload.burn_after_reading,
      password_protected: payload.password_protected,
      has_message: payload.ciphertext.present? && payload.ciphertext.bytesize > 0,
      file_count: payload.encrypted_files.count,
      total_size_bytes: total_size,
      total_size_human: number_to_human_size(total_size)
    }
  end

  private

  def decryption_service
    @decryption_service ||= DecryptionService.new(params[:id])
  end

  def check_session_flags
    @show_error = session.delete(:payload_expired)
  end
end
