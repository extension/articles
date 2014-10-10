Honeybadger.configure do |config|
  config.api_key = Settings.honeybadger_api_key
  config.environment_name = Settings.app_location
end
