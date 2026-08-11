# config/initializers/openai.rb
require "openai"

OpenAI.configure do |config|
  openrouter_key = ENV["OPENROUTER_API_KEY"].to_s.strip
  openrouter_credential_key = Rails.application.credentials.dig(:openrouter, :api_key).to_s.strip
  legacy_openai_key = ENV["OPENAI_API_KEY"].to_s.strip
  legacy_openai_credential_key = Rails.application.credentials.dig(:openai, :api_key).to_s.strip

  config.access_token =
    openrouter_key.presence ||
    openrouter_credential_key.presence ||
    legacy_openai_key.presence ||
    legacy_openai_credential_key.presence

  config.uri_base = ENV.fetch("OPENROUTER_URI_BASE", "https://openrouter.ai/api/v1")

  send_attribution = ActiveModel::Type::Boolean.new.cast(ENV.fetch("OPENROUTER_SEND_ATTRIBUTION", "false"))
  if send_attribution
    extra_headers = {}
    http_referer = ENV["OPENROUTER_HTTP_REFERER"].to_s.strip
    app_name = ENV["OPENROUTER_APP_NAME"].to_s.strip
    extra_headers["HTTP-Referer"] = http_referer if http_referer.present?
    extra_headers["X-Title"] = app_name if app_name.present?
    config.extra_headers = extra_headers if extra_headers.any?
  end
end
