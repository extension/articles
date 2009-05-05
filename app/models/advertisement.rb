class Advertisement < ActiveRecord::Base
  belongs_to :image, :class_name => "Asset"
  belongs_to :tag
  
  acts_as_list
  
  def self.tags
    adtags = Community.tags

    adtags.sort!{|a, b| a.name <=> b.name}
    adtags.unshift( Tag.find_by_name('main') )
    adtags.delete(nil)
    adtags
  end
    
  # returns a collection of advertisements, ordered based on the position field
  def self.prioritized_for_tag(tag = nil)
    if tag.nil?
      Advertisement.find(:all, :order => 'position')
    else
      Advertisement.find_all_by_tag_id(tag.id, :order => 'position')
    end
  end
end
