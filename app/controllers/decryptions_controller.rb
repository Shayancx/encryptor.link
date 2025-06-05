# frozen_string_literal: true

class DecryptionsController < ApplicationController
  before_action :check_session_flags, only: :show

  def show
    @payload_info = decryption_service.payload_info
    render :show
  end

  def data
    response_data = decryption_service.retrieve_data

    if response_data
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
