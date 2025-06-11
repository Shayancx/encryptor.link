module Api
  module V1
    class HealthController < ApplicationController
      def index
        render json: {
          status: 'healthy',
          environment: Rails.env,
          ruby_version: RUBY_VERSION,
          rails_version: Rails.version,
          database: {
            adapter: ActiveRecord::Base.connection.adapter_name.downcase,
            connected: ActiveRecord::Base.connected?,
          },
          timestamp: Time.current
        }
      end
    end
  end
end
