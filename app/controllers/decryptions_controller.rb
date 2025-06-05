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

  private

  def decryption_service
    @decryption_service ||= DecryptionService.new(params[:id])
  end

  def check_session_flags
    @show_error = session.delete(:payload_expired)
  end
end
