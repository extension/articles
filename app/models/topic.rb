# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Topic < ActiveRecord::Base
  include CacheTools
  COMMUNITY_ASSOCIATION_CACHE_EXPIRY = 24.hours

  has_many :publishing_communities, :foreign_key => 'public_topic_id'

  def launched_communities(forcecacheupdate=false)
    self.publishing_communities(:include => :taggings, :conditions => "publishing_communities.is_launched = TRUE", :order => 'publishing_communities.public_name')
  end

  def self.topics_list
    self.joins(:publishing_communities).where("publishing_communities.is_launched = TRUE").order("topics.name ASC, publishing_communities.public_name").uniq
  end

  def self.frontporch_hashlist(cache_options = {expires_in: COMMUNITY_ASSOCIATION_CACHE_EXPIRY})
    cache_key = self.get_cache_key(__method__)
    Rails.cache.fetch(cache_key,cache_options) do
      topics_hash = {}
      topics_list.each do |topic|
        communities = topic.publishing_communities.includes(:primary_tag).where("publishing_communities.is_launched = TRUE").order('publishing_communities.public_name')
        topics_hash[topic.name] = []
        communities.each do |community|
          topics_hash[topic.name] << {:id => community.id, :public_name => community.public_name, :primary_tag_name => community.primary_tag_name}
        end
      end
      topics_hash
    end
  end


end
