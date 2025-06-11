module Api
  module V1
    class MessagesController < ApplicationController
      # GET /api/v1/messages/:id
      def show
        message = Message.find_by(id: params[:id])
        
        if message && !message.deleted?
          render json: {
            id: message.id,
            encrypted_data: message.encrypted_data,
            created_at: message.created_at,
            expires_at: message.expires_at,
            remaining_views: calculate_remaining_views(message),
            deleted: message.deleted?
          }
        else
          render json: { error: 'Message not found or has been deleted' }, status: :not_found
        end
      end

      # POST /api/v1/messages
      def create
        Rails.logger.info "=== Creating message ==="
        Rails.logger.info "Raw params: #{params.inspect}"
        Rails.logger.info "Request body: #{request.raw_post}"
        
        begin
          # Extract the data from nested structure
          message_data = params[:data] || params
          
          Rails.logger.info "Message data: #{message_data.inspect}"
          
          message = Message.new(
            encrypted_data: message_data[:encrypted_data],
            metadata: message_data[:metadata] || {}
          )
          
          Rails.logger.info "Message object: #{message.inspect}"
          
          if message.save
            Rails.logger.info "Message created successfully: #{message.id}"
            render json: { 
              id: message.id,
              created_at: message.created_at,
              expires_at: message.expires_at
            }, status: :created
          else
            Rails.logger.error "Message creation failed: #{message.errors.full_messages}"
            render json: { error: message.errors.full_messages.join(', ') }, status: :unprocessable_entity
          end
        rescue => e
          Rails.logger.error "Exception in create: #{e.class}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: "Internal server error: #{e.message}" }, status: :internal_server_error
        end
      end

      # POST /api/v1/messages/:id/view
      def view
        message = Message.find_by(id: params[:id])
        
        if message&.increment_view_count
          render json: { status: 'success', message: 'View count incremented' }
        else
          render json: { error: 'Failed to increment view count' }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/messages/:id
      def destroy
        message = Message.find_by(id: params[:id])
        
        if message&.mark_as_deleted
          render json: { status: 'success', message: 'Message deleted' }
        else
          render json: { error: 'Failed to delete message' }, status: :unprocessable_entity
        end
      end

      private
      
      def calculate_remaining_views(message)
        return nil unless message.metadata&.dig('max_views')
        max_views = message.metadata['max_views'].to_i
        [max_views - message.view_count, 0].max
      end
    end
  end
end
