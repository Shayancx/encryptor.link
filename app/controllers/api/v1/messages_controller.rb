module Api
  module V1
    class MessagesController < ApplicationController
      skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
      
      def index
        render json: { status: 'success', message: 'API is operational' }
      end
      
      # This is a stub - in a real app you'd have proper message handling
      def create
        render json: { 
          status: 'success', 
          message: 'Message stored securely',
          data: {
            id: SecureRandom.uuid,
            created_at: Time.now
          }
        }
      end
    end
  end
end
