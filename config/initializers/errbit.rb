Airbrake.configure do |config|
		 config.api_key		 	= AppConfig.configtable['airbrake_api_key']
		 config.host				= 'apperrors.extension.org'
		 config.port				= 443
		 config.secure			= config.port == 443
		 config.ignore       << "ActionController::UnknownHttpMethod"
	 end
