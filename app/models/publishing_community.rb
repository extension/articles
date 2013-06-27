# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at https://github.com/extension/darmok/wiki/LICENSE

class PublishingCommunity < ActiveRecord::Base
  serialize :cached_content_tag_data
  extend ConditionExtensions
  has_content_tags
  ordered_by :default => "#{self.table_name}.name ASC"


  # topics for public site
  belongs_to :topic, :foreign_key => 'public_topic_id'
  belongs_to :logo
  belongs_to :homage, :class_name => "Page", :foreign_key => "homage_id"
  validates_format_of :twitter_handle, :facebook_handle, :youtube_handle, :pinterest_handle, :gplus_handle, :with => URI::regexp(%w(http https)), :allow_blank => true

  named_scope :tagged_with_content_tag, lambda {|tagname| 
    {:include => {:taggings => :tag}, :conditions => "tags.name = '#{tagname}' AND taggings.tagging_kind = #{Tagging::CONTENT}"}
  }

  named_scope :ordered_by_topic, {:include => :topic, :order => 'topics.name ASC, communities.public_name ASC'}
  named_scope :launched, {:conditions => {:is_launched => true}}

  def primary_content_tag_name(force_cache_update=false)    
    self.cached_content_tags(force_cache_update)[0]
  end
    
  # returns a comma delimited of the tags - with the primary content tag name first in the list
  # used for community editing in the administrative interface for public communities
  def content_tag_names(force_cache_update=false)
    self.cached_content_tags(force_cache_update).join(Tag::JOINER)
  end  
  
  # this will silently strip out content tags in use by other communities
  # it's up to the controller level to deal with the warnings on this
  def content_tag_names=(taglist)
    # get content tags in use by other communities
    my_content_tags = tags_by_ownerid_and_kind(Person.systemuserid,Tagging::CONTENT)
    other_community_tags = Tag.community_content_tags - my_content_tags
    other_community_tag_names = other_community_tags.map(&:name)
    updatelist = Tag.castlist_to_array(taglist,true)
    primary = updatelist[0]
    
    # primary tag - first in the list
    if(!other_community_tag_names.include?(primary) and !Tag::CONTENTBLACKLIST.include?(primary))
      self.replace_tags(primary,Person.systemuserid,Tagging::CONTENT_PRIMARY)
    end
    
    # okay, do all the tags as CONTENT taggings - updating the cached_tags for search
    self.replace_tags(updatelist.reject{|tname| (other_community_tag_names.include?(tname) or Tag::CONTENTBLACKLIST.include?(tname))},Person.systemuserid,Tagging::CONTENT)
    
    # update the Tag model's community_content_tags
    cctags = Tag.community_content_tags({:all => true},true)
    if(self.is_launched?)
      Tag.community_content_tags({:launchedonly => true},true)       
    end
    
    # now update the cached content community for each tag
    cctags.each do |t|
      t.content_community
    end
    
    # now update my cached_content_tags
    taglist = self.cached_content_tags(true)
    

    
    return taglist.join(Tag::JOINER)
  end
    
  # returns an array of the names
  def cached_content_tags(force_cache_update=false)
    if(self.cached_content_tag_data.blank? or self.cached_content_tag_data[:primary_tag].blank? or self.cached_content_tag_data[:all_tags].blank? or force_cache_update)
      # get primary content tag first - should be only one - and if not, we'll force it anyway
      primary_tags = tags_by_ownerid_and_kind(Person.systemuserid,Tagging::CONTENT_PRIMARY)
      if(!primary_tags.blank?)
        tagarray = []
        primary_content_tag = primary_tags[0]
        tagarray << primary_content_tag
        # get the rest...
        other_content_tags = tags_by_ownerid_and_kind(Person.systemuserid,Tagging::CONTENT)
        other_content_tags.each do |tag| 
          if(tag != primary_content_tag)
            tagarray << tag
          end
        end
        tagarray += other_content_tags if !other_content_tags.blank?
      else
        tagarray = tags_by_ownerid_and_kind(Person.systemuserid,Tagging::CONTENT)
      end
      
      cachedata = {}
      if(!tagarray.blank?)
        cachedata[:primary_tag] = {:id => tagarray[0].id, :name => tagarray[0].name}
        cachedata[:all_tags] = {}
        tagarray.map{|t| cachedata[:all_tags][t.id] = t.name}
      end
      update_attribute(:cached_content_tag_data, cachedata)
    else
      cachedata =  self.cached_content_tag_data
    end

    returntagarray = []
    if(!cachedata[:primary_tag].nil?)    
      primary_tag_name = cachedata[:primary_tag][:name] 
      returntagarray << primary_tag_name    
      cachedata[:all_tags].each do |id,name| 
        if(name != primary_tag_name)
          returntagarray << name
        end
      end
    end          
    return returntagarray
  end


  def ask_an_expert_group_url
    if(self.aae_group_id.blank?)
      nil
    else
      "#{AppConfig.configtable['ask_two_point_oh']}groups/#{self.aae_group_id}"
    end
  end


def update_create_group_resource_tags
  drupaldatabase = AppConfig.configtable['create_database']
  if(self.drupal_node_id.blank?)
    return true
  end

  insert_values = []
  self.cached_content_tags(true).each do |content_tag|
    if(content_tag == self.primary_content_tag_name)
      primary = 1
    else
      primary = 0
    end
    insert_values << "(#{self.drupal_node_id},#{ActiveRecord::Base.quote_value(self.name)},#{self.id},#{ActiveRecord::Base.quote_value(content_tag)},#{primary})"
  end

  if(!insert_values.blank?)
    insert_sql = "INSERT INTO #{drupaldatabase}.group_resource_tags (nid,community_name,community_id,resource_tag_name,is_primary_tag)"
    insert_sql += " VALUES #{insert_values.join(',')}"
    
    self.connection.execute("DELETE FROM #{drupaldatabase}.group_resource_tags WHERE nid = #{self.drupal_node_id}")
    self.connection.execute(insert_sql)
  end
  
  return true;
end


end