Airbrake.configure do |config|
  config.api_key = AppConfig.configtable['airbrake_api_key']
end
