require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IncidentsBot
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true

    # Timeouts
    config.middleware.insert_before 0, Rack::Timeout

    # Rate limiting
    config.middleware.use Rack::Attack

    # Lograge (JSON-ish logs)
    config.lograge.enabled = true
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.custom_payload do |controller|
      {
        request_id: controller.request.request_id,
        user_agent: controller.request.user_agent,
        bot_activity_type: controller.instance_variable_get(:@bot_activity_type)
      }
    end
  end
end