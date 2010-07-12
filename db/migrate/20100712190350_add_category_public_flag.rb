class AddCategoryPublicFlag < ActiveRecord::Migration
  def self.up
    add_column(:categories, :show_to_public, :boolean, :default => false)
    Category.reset_column_information
    Category.record_timestamps=true
    
    # convert launched content categories
    # get the content tags for launched communities and map to a string we can limit a category find to.
    retrieveoptions = {:launchedonly => true, :onlyaae => true}
    launched_community_content_tags = Tag.community_content_tags(retrieveoptions).map{|t| "'#{t.name}'"}
    categorylist = Category.find(:all, :conditions => "parent_id IS NULL and LOWER(name) IN (#{launched_community_content_tags.join(',')})", :order => 'name')
    
    categorylist.each do |category|
      execute "UPDATE categories SET show_to_public = 1 WHERE categories.id = #{category.id} or parent_id = #{category.id}"
    end
    
  end

  def self.down
    remove_column(:categories, :show_to_public)
  end
end
