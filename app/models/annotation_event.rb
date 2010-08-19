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
  
  def self.changes_feed
    params = {:feed_title => "Search - Annotation Changes",
              :alt_link => url_for(:controller => 'search',
                                   :action => 'index', :only_path => false)}
    feed = new Feed.new(params)
    feed.serve
  end
end