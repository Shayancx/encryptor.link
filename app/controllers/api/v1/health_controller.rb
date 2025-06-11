module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :verify_authenticity_token

      def index
        render json: {
          status: 'healthy',
          timestamp: Time.current.iso8601,
          environment: Rails.env,
          ruby_version: RUBY_VERSION,
          rails_version: Rails.version,
          database: {
            adapter: ActiveRecord::Base.connection.adapter_name.downcase,
            connected: ActiveRecord::Base.connected?,
          }
        }
      end
    end
  end
end
