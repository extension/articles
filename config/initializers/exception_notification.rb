# exception notifier settings
ExceptionNotifier.exception_recipients = AppConfig.configtable['mail_errors_to']
ExceptionNotifier.sender_address = %("darmok-#{AppConfig.configtable['mail_label']}" <exdev@extension.org>)
ExceptionNotifier.email_prefix = "[darmok-#{AppConfig.configtable['mail_label']}] "
