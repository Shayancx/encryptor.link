module Api
  module V1
    class MessagesController < ApplicationController
      skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
      before_action :set_message, only: [:show, :view, :destroy]

      # GET /api/v1/messages/:id
      def show
        if @message
          if @message.deleted?
            render json: { error: 'Message has been deleted or expired' }, status: :gone
          else
            render json: {
              id: @message.id,
              encrypted_data: @message.encrypted_data,
              created_at: @message.created_at,
              expires_at: @message.expires_at,
              remaining_views: @message.max_views ? (@message.max_views - @message.view_count) : nil,
              deleted: @message.deleted?
            }
          end
        else
          render json: { error: 'Message not found' }, status: :not_found
        end
      end

      # POST /api/v1/messages
      def create
        # Sanitize and prepare parameters
        message_params_hash = message_params_to_hash
        
        @message = Message.new(
          encrypted_data: message_params_hash[:encrypted_data],
          metadata: message_params_hash[:metadata]
        )
        
        if @message.save
          render json: { 
            id: @message.id,
            created_at: @message.created_at,
            expires_at: @message.expires_at
          }, status: :created
        else
          render json: { error: @message.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/messages/:id/view
      def view
        if @message&.increment_view_count
          render json: { status: 'success', message: 'View count incremented' }
        else
          render json: { error: 'Failed to increment view count' }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/messages/:id
      def destroy
        if @message&.mark_as_deleted
          render json: { status: 'success', message: 'Message deleted' }
        else
          render json: { error: 'Failed to delete message' }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/health
      def health
        render json: { status: 'healthy', message: 'API is operational', environment: Rails.env }
      end

      private

      def set_message
        @message = Message.find_by(id: params[:id])
      end

      def message_params_to_hash
        data_params = params.require(:data).permit!.to_h
        {
          encrypted_data: data_params[:encrypted_data],
          metadata: data_params[:metadata]
        }
      end
      
      # This is the old method that might fail with nested params
      def message_params
        params.require(:data).permit(
          :encrypted_data,
          metadata: {}
        )
      end
    end
  end
end
