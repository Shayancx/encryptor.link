require "net/http"
require "uri"
require "json"

class SlackNotificationJob < ApplicationJob
  queue_as :default

  def perform(webhook_url:, message:)
    uri = URI.parse(webhook_url)
    Net::HTTP.post(uri, { text: message }.to_json, "Content-Type" => "application/json")
  rescue StandardError => e
    Rails.logger.error "Slack notification failed: #{e.message}"
  end
end
