require 'has_tags'
require 'ordered'
require 'utility_scopes'

ActiveRecord::Base.class_eval do
  include Extension::HasTags
  include Extension::Ordered
  include Extension::UtilityScopes
end
