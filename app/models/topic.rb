class Topic < ActiveRecord::Base
  has_many :communities
  
  def self.find_with_communities
    self.find :all, :include => :communities, :conditions => ['communities.visible = 1'], :order => 'topics.name ASC, communities.name ASC'
  end
  
end