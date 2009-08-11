# exception notifier settings
ExceptionNotifier.exception_recipients = AppConfig.configtable['emailsettings']['errors']
ExceptionNotifier.sender_address = %("darmok-#{AppConfig.configtable['app_location']}" <exdev@extension.org>)
ExceptionNotifier.email_prefix = "[darmok-#{AppConfig.configtable['app_location']}] "
