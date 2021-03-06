source 'https://rubygems.org'

gem 'rails', '3.2.22.5'

# all things xml
gem 'nokogiri'

# data
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
# speed up sppppppprooooockets
gem 'turbo-sprockets-rails3'
group :assets do
  gem 'uglifier'
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  # files for bootstrap-in-asset-pipeline integration
  gem 'bootstrap-sass', '~> 2.3.2.2'
  gem 'jquery-ui-rails'
  # extension's packaging of html5shiv for the asset pipeline
  gem 'extension-html5shiv-rails', :require => 'html5shiv-rails', :source => 'https://engineering.extension.org/rubygems'
  # replaces glyphicons
  gem 'font-awesome-rails'
end

# # mobile device detection
# gem 'mobile-fu'

# server settings
gem "rails_config"

# more xml
gem 'hpricot'

# atom parsing
# gem 'ratom', :require => 'atom',  github: 'extension/ratom', branch: "master"
gem 'feedjira'

# authentication
gem 'omniauth', ">= 1.0"
gem 'omniauth-openid'

# jquery magick
gem 'jquery-rails'

# pagination
gem 'kaminari'

# command line tools
gem 'thor'

# exception handling
gem 'honeybadger'

# useragent analysis
gem 'useragent'

# ip to geo mapping
gem 'geocoder'
gem 'geoip'

# image sizing
gem 'fastimage'

# cron management
gem 'lockfile'

# memcached
gem 'dalli'

# attachment_fu plugin replacement
gem "pothoven-attachment_fu"
gem 'rmagick', :require => false

# acts_as_list
gem 'acts_as_list'

# catch rack errors
gem 'rack-robustness'

# kill off bad behavior
gem 'rack-attack'

# legacy data support
gem 'safe_attributes'

# terse logging
gem 'lograge'

# exif data
gem 'mini_exiftool'

# mime type determination
gem 'mimemagic'

# Ruby 2.2 requirement
gem 'test-unit'

# Background processing
gem 'sidekiq', '< 3'
gem 'sinatra', '< 2'

# prevent iframe crap
# gem "secure_headers"

group :development do
  # require the powder gem
  gem 'powder'
  # require puma for those switching to puma
  gem 'puma'
  # debug http requests
  gem 'net-http-spy'
  # jason uses pry, forces the gem on everyone
  gem 'pry'
  # deployment
  gem 'capistrano', '~> 2.15.5'
  gem 'capatross'
  # shut the asset requests up in dev log
  gem 'quiet_assets'
  # fun things for dealing with 500 errors
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

end
