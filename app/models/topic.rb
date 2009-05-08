class Topic < ActiveRecord::Base
  has_many :communities
  
  def self.find_with_communities
    self.find :all, :include => :communities, :conditions => ['communities.is_launched = 1'], :order => 'topics.name ASC, communities.public_name ASC'
  end
  
end