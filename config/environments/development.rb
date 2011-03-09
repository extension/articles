# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
config.active_record.colorize_logging = false
# development gems
if(AppConfig.configtable['load_rails_footnotes'])
  config.gem 'rails-footnotes', :version => '~>3.6', :lib => "rails-footnotes"
end

# email settings
config.action_mailer.delivery_method = :smtp
config.action_mailer.default_charset = "utf-8"
config.action_mailer.smtp_settings = {
  :address => "sendmail.extension.org",
  :port => 25,
  :domain => "extension.org"
}

config.action_mailer.perform_deliveries = false

if(AppConfig.configtable['load_query_trace'])
  require 'query_trace'
  
  class ::ActiveRecord::ConnectionAdapters::AbstractAdapter
    include QueryTrace
  end
end