# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file or view at https://github.com/extension/darmok/wiki/LICENSE

class PublishingCommunity < ActiveRecord::Base
  extend ConditionExtensions
  include Ordered

  ordered_by :default => "#{self.table_name}.name ASC"

  # topics for public site
  belongs_to :topic, :foreign_key => 'public_topic_id'
  belongs_to :logo
  belongs_to :homage, :class_name => "Page", :foreign_key => "homage_id"
  belongs_to :primary_tag, :class_name => "Tag"
  has_many :taggings, :as => :taggable, dependent: :destroy
  has_many :tags, :through => :taggings
  has_many :pages, :through => :tags
  has_many :image_data, :through => :pages

  validates_format_of :twitter_handle, :facebook_handle, :youtube_handle, :pinterest_handle, :gplus_handle, :with => URI::regexp(%w(http https)), :allow_blank => true

  scope :ordered_by_topic, {:include => :topic, :order => 'topics.name ASC, communities.public_name ASC'}
  scope :launched, {:conditions => {:is_launched => true}}

  scope :tagged_with, lambda{|tagliststring|
    tag_list = Tag.castlist_to_array(tagliststring)
    in_string = tag_list.map{|t| "'#{t}'"}.join(',')
    joins(:tags).where("tags.name IN (#{in_string})").group("#{self.table_name}.id").having("COUNT(#{self.table_name}.id) = #{tag_list.size}")
  }

  scope :tagged_with_any, lambda { |tagliststring|
    tag_list = Tag.castlist_to_array(tagliststring)
    in_string = tag_list.map{|t| "'#{t}'"}.join(',')
    joins(:tags).where("tags.name IN (#{in_string})").group("#{self.table_name}.id")
  }

  def primary_tag_name
    self.primary_tag.present? ? self.primary_tag.name : nil
  end

  # returns a comma delimited of the tags - with the primary content tag name first in the list
  # used for community editing in the administrative interface for public communities
  def tag_names
    returntags = []
    returntags << primary_tag_name
    returntags += tags.map(&:name)
    returntags.uniq.compact
  end

  # this will silently strip out content tags in use by other communities
  # it's up to the controller level to deal with the warnings on this
  def tag_names=(taglist)
    # get content tags in use by other communities
    my_content_tags = self.tags
    other_community_tags = Tag.community_tags - my_content_tags
    other_community_tag_names = other_community_tags.map(&:name)
    updatelist = Tag.castlist_to_array(taglist,true)
    primary = updatelist[0]

    # okay, do all the tags as CONTENT taggings - updating the cached_tags for search
    self.replacetags_fromlist(updatelist.reject{|tname| (other_community_tag_names.include?(tname) or Tag::CONTENTBLACKLIST.include?(tname))})

    # after the tag was potentially created, set the primary tag setting
    if(!other_community_tag_names.include?(primary) and !Tag::CONTENTBLACKLIST.include?(primary))
      if(primary_tag = Tag.where(name: primary).first)
        self.update_attribute(:primary_tag_id, primary_tag.id)
      end
    end

    return updatelist.join(Tag::JOINER)
  end


  def ask_an_expert_group_url
    if(self.aae_group_id.blank?)
      nil
    else
      "#{Settings.ask_two_point_oh}groups/#{self.aae_group_id}"
    end
  end


  def update_create_group_resource_tags
    drupaldatabase = Settings.create_database
    if(self.drupal_node_id.blank?)
      return true
    end

    insert_values = []
    self.tag_names.each do |content_tag|
      if(content_tag == self.primary_tag_name)
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

  def replacetags_fromlist(taglist)
    replacelist = Tag.castlist_to_array(taglist)
    newtags = []
    replacelist.each do |tagname|
      if(tag = Tag.where(name: tagname).first)
        newtags << tag
      else
        newtags << Tag.create(name: tagname)
      end
    end
    self.tags = newtags
  end




end
