# The pointer to the actual feed from which articles will be retrieved.
class FeedLocation < ActiveRecord::Base
  
  validates_length_of :uri, :within => 1..255
  
  named_scope :active, :conditions => { :active => true }
end
