class ChunksController < ApplicationController
  def create
    chunk_id = SecureRandom.hex(16)
    session_id = params[:session_id]

    Rails.cache.write(
      "chunk:#{session_id}:#{chunk_id}",
      params[:chunk],
      expires_in: 1.hour
    )

    render json: { chunk_id: chunk_id }
  end

  def finalize
    head :no_content
  end
end
