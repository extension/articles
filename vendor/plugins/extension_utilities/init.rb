require 'has_tags'
require 'has_feeds'
require 'ordered'
require 'utility_scopes'

ActiveRecord::Base.class_eval do
  include Extension::HasTags
  include Extension::HasFeeds
  include Extension::Ordered
  include Extension::UtilityScopes
end
