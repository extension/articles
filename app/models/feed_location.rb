# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# The pointer to the actual feed from which articles will be retrieved.
class FeedLocation < ActiveRecord::Base
  validates_length_of :uri, :within => 1..255
  named_scope :active, :conditions => { :active => true }
  has_many :update_times, :as => :datasource
  
  
  # retrieves content from this feed_url and creates ExternalArticle objects
  def retrieve_articles(options = {})
    retrieve_options = options.dup
    retrieve_options[:datatype] = 'ExternalArticle'
    
    # don't update retrieve time for ExternalArticle, instead update a time per feed
    retrieve_options[:update_retrieve_time] = false
    updatetime = UpdateTime.find_or_create(self,'articles')
    
    # note, this time will be ignored by ExternalArticle.retrieve_content if we don't retrieve_with time
    # but we'll set it anyway in order to update the time that the data was last pulled
    if(retrieve_options[:refresh_since].nil?)
      retrieve_options[:refresh_since] = updatetime.last_datasourced_at
    end
      
    if(retrieve_options[:refresh_without_time].nil?)
      if(!self.retrieve_with_time?)
        retrieve_options[:refresh_without_time] = true
      end
    end
    
    if(retrieve_options[:feed_url].nil?)
      retrieve_options[:feed_url] = self.uri
    end
    
    results = Article.retrieve_content(retrieve_options)
    if(!results[:last_updated_item_time].nil?)
      updatetime.update_attributes({:last_datasourced_at => results[:last_updated_item_time] + 1, :additionaldata => {:deleted => results[:deleted], :added => results[:added], :updated => results[:updated]}})        
    else
      updatetime.touch
    end
    return results
  end
  
end
