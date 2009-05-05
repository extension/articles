require 'has_categories'
require 'ordered'
require 'utility_scopes'

ActiveRecord::Base.class_eval do
  include Extension::HasCategories
  include Extension::Ordered
  include Extension::UtilityScopes
end