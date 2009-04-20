# exception notifier settings
ExceptionNotifier.exception_recipients = AppConfig.configtable['mail_errors_to']
ExceptionNotifier.sender_address = %("identity-#{AppConfig.configtable['mail_label']}" <exdev@extension.org>)
ExceptionNotifier.email_prefix = "[identity-#{AppConfig.configtable['mail_label']}] "
