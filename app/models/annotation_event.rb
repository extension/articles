# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class AnnotationEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :annotation, :primary_key => :url
  serialize :additionaldata
  
  URL_ADDED = 'added'
  URL_DELETED = 'deleted'
  
  def url
    return self.annotation_id
  end
  
  def self.log_event(opts)
    # user and login convenience column
    if(opts[:user].nil?)
      opts[:login] = ((opts[:additionaldata].nil? or opts[:additionaldata][:login].nil?) ? 'unknown' : opts[:additionaldata][:login])
    else
      opts[:login] = opts[:user].login
    end

    # ip address
    if(opts[:ip].nil?)
      opts[:ip] = AppConfig.configtable['request_ip_address']
    end
    
    AnnotationEvent.create(opts)
  end
  
  def self.find_with_feed
      dpl_tag = Tag.find_by_name("dpl")

      alias_name = type

      select = "SQL_CALC_FOUND_ROWS "+alias_name+".*"

      conditions = ['']
      conditions.first << alias_name+".updated_at >= ?"
      conditions.concat([updated_min])
      conditions.first << " and "+alias_name+".updated_at < ?"
      conditions.concat([updated_max])

      if type == 'learn'
        conditions.first << " and "+alias_name+".session_start >= ?"
        conditions.concat([published_min])
        conditions.first << " and "+alias_name+".session_start < ?"
        conditions.concat([published_max])
      else
        conditions.first << " and "+alias_name+".created_at >= ?"
        conditions.concat([published_min])
        conditions.first << " and "+alias_name+".created_at < ?"
        conditions.concat([published_max])
      end
      
      joins = "as "+alias_name
      
      limit = "#{start_index - 1}, #{max_results - 1}"
      
      if category_array
        entries = klass.tagged_with_content_tags(category_array).ordered.limit(limit).
                    find(:all, :select => select, :conditions => conditions)
      else
        entries = klass.ordered.limit(limit).find(:all, :select => select,
                      :joins => joins,
                      :conditions => conditions)
      end
      
      total_possible_results = entries.empty? ? 0 : entries[0].class.count_by_sql("SELECT FOUND_ROWS()")
      
      return entries, total_possible_results
  end
  
  def self.changes_feed
    params = {:feed_title => "Search - Annotation Changes",
              :alt_link => url_for(:controller => 'search',
                                   :action => 'index', :only_path => false)}
    @feed = Feed.new(params)
    entries, total_possible_results = AnnotationEvent.find_with_feed
    feed.serve(entries, total_possible_results)
  end
end