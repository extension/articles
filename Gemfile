source 'https://rubygems.org'
source 'https://systems.extension.org/rubygems/'

gem 'rails', '3.2.16'

# all things xml
gem 'nokogiri', '1.5.10'

# data
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
# speed up sppppppprooooockets
gem 'turbo-sprockets-rails3'
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  # files for bootstrap-in-asset-pipeline integration
  gem 'anjlab-bootstrap-rails', '~> 2.0', :require => 'bootstrap-rails'
  gem 'jquery-ui-rails'
  gem 'extension-html5shiv-rails', :require => 'html5shiv-rails'
end

# # mobile device detection
# gem 'mobile-fu'

# server settings
gem "rails_config"

# more xml
gem 'hpricot'

# atom parsing
gem 'ratom', :require => 'atom'

# authentication
gem 'omniauth', "~> 1.0"
gem 'omniauth-openid'

# jquery magick
gem 'jquery-rails'

# pagination
gem 'will_paginate'
# command line tools
gem 'thor'

# exception handling
gem 'airbrake'

# caching
gem 'redis-rails'

# useragent analysis
gem 'useragent'

# ip to geo mapping
gem 'geocoder'
gem 'geoip'

# image submission and other image handling
# gem 'paperclip'
# gem 'rmagick', :require => false

# image sizing
gem 'fastimage'

# cron management
gem 'lockfile'

# memcached
gem 'dalli'

# attachment_fu plugin replacement
gem "pothoven-attachment_fu"

# acts_as_list
gem 'acts_as_list'

group :development do
  # require the powder gem
  gem 'powder'
  gem 'net-http-spy'
  gem 'pry'
  gem 'capistrano', '~> 2.15.5' 
  gem 'capatross'

  # moar advanced stats in dev only
  #gem 'gsl', :git => 'git://github.com/30robots/rb-gsl.git'
  #gem 'statsample-optimization', :require => 'statsample'

  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

end




