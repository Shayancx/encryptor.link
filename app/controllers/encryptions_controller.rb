# frozen_string_literal: true

class EncryptionsController < ApplicationController
  def new
    render :new
  end

  def create
    service = EncryptionService.new(encryption_params)
    payload = service.create_payload

    render json: {
      id: payload.id,
      password_protected: payload.password_protected
    }
  rescue EncryptionService::EncryptionError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Unexpected error in EncryptionsController#create: #{e.class}: #{e.message}"
    render json: { error: "An unexpected error occurred" }, status: :internal_server_error
  end

  private

  def encryption_params
    params.permit(:ciphertext, :nonce, :ttl, :views, :password_protected,
                  :password_salt, :burn_after_reading,
                  files: [ :data, :name, :type, :size ])
  end
end
