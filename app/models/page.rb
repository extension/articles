# === COPYRIGHT:
# Copyright (c) 2005-2010 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'uri'
class Page < ActiveRecord::Base
  include ActionController::UrlWriter # so that we can generate URLs out of the model
  include TaggingScopes
  
end