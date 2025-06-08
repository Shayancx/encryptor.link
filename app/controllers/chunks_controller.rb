class ChunksController < ApplicationController
  def create
    chunk_id = SecureRandom.hex(16)
    session_id = params[:session_id]

    chunk_params = params.require(:chunk).permit(:offset, :data, :originalSize)

    Rails.cache.write(
      "chunk:#{session_id}:#{chunk_id}",
      chunk_params.to_h,
      expires_in: 1.hour
    )

    render json: { chunk_id: chunk_id }
  end

  def finalize
    head :no_content
  end
end
