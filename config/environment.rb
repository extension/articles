# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '~>2.3.3' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem 'will_paginate', :version => '~>2.3', :lib => 'will_paginate', :source => 'http://systems.extension.org/rubygems/'
  config.gem 'ruby-openid', :version => '~>2.1', :lib => 'openid', :source => 'http://systems.extension.org/rubygems/'
  config.gem 'has_many_polymorphs', :version => '~>2.13', :source => 'http://systems.extension.org/rubygems/'
  config.gem 'ratom', :version => '~>0.6', :lib => 'atom', :source => 'http://systems.extension.org/rubygems/'
  config.gem 'hpricot', :version => '~>0.8', :source => 'http://systems.extension.org/rubygems/'
  config.gem 'tzinfo', :version => '~>0.3', :source => 'http://systems.extension.org/rubygems/'
  config.gem 'geokit', :version => '~>1.5', :source => 'http://systems.extension.org/rubygems/'
  config.gem "nokogiri", :version => '~>1.4', :source => 'http://systems.extension.org/rubygems/'
  config.gem "paperclip", :version => '~>2.3', :source => 'http://systems.extension.org/rubygems/'
  config.gem "calendar_date_select"
  config.gem 'gdata', :version => '~>1.1', :lib => 'gdata', :source => 'http://systems.extension.org/rubygems/'
  # required by cron'd scripts that need to have a lock on running
  config.gem 'lockfile', :version => '~>1.4', :lib => 'lockfile', :source => 'http://systems.extension.org/rubygems/'
  # required by fetcher library
  config.gem 'SystemTimer', :version => '~>1.2', :lib => 'system_timer', :source => 'http://systems.extension.org/rubygems/'
  # required for IP branding
  config.gem 'geoip', :source => 'http://systems.extension.org/rubygems/'
  # required for email parsing
  config.gem 'mail'
  config.gem 'fake_arel'
  
  # TODO: still need pubsite gems - http://justcode.extension.org/issues/show/521

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  # cache configuration
  config.cache_store = :mem_cache_store, 'localhost', {:namespace => 'pubsite'}
end

# enable Garbage Collection 
GC.enable_stats if defined?(GC) && GC.respond_to?(:enable_stats)

# require for tagging
# commented out for now
# TODO: figure out why this has to be in environment.rb
require 'tagging_extensions'
