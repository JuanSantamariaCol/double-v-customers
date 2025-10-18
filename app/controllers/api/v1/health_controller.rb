module Api
  module V1
    class HealthController < ApplicationController
      # GET /api/v1/health
      def show
        begin
          # Check database connection
          ActiveRecord::Base.connection.execute("SELECT 1")

          render json: {
            status: "ok",
            service: "customers-service",
            timestamp: Time.current.iso8601,
            database: "connected",
            version: "1.0.0"
          }
        rescue => e
          render json: {
            status: "error",
            service: "customers-service",
            timestamp: Time.current.iso8601,
            database: "disconnected",
            error: e.message
          }, status: :service_unavailable
        end
      end
    end
  end
end
