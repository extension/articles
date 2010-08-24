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
  
  def to_atom_entry
    Atom::Entry.new do |e|
      e.title = Atom::Content::Html.new(self.title)
      e.links << Atom::Link.new(:type => "text/html", :rel => "alternate", :href => self.id_and_link)
      e.authors << Atom::Person.new(:name => 'Contributors')
      e.id = self.id_and_link
      e.updated = self.wiki_updated_at
      e.categories = self.content_tag_names.map{|name| Atom::Category.new({:term => name, :scheme => url_for(:controller => 'main', :action => 'index')})}
      e.content = Atom::Content::Html.new(self.content)
    end
  end
  
  def id_and_link
    default_url_options[:host] = AppConfig.get_url_host
    default_url_options[:protocol] = AppConfig.get_url_protocol
    if(default_port = AppConfig.get_url_port)
      default_url_options[:port] = default_port
    end
    annotation_event_page_url(:id => self.id.to_s)
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
    select = "SQL_CALC_FOUND_ROWS #{self.table_name}.*"

    conditions = ['']

    conditions.first << "#{self.table_name}.created_at >= ?"
    conditions.concat([@feed.gdata_params[:published_min]])
    conditions.first << " and #{self.table_name}.created_at < ?"
    conditions.concat([@feed.gdata_params[:published_max]])
        
    limit = "#{@feed.gdata_params[:start_index] - 1}, #{@feed.gdata_params[:max_results] - 1}"
    
    entries = self.ordered.limit(limit).find(:all, :select => select,
                  :conditions => conditions)
    
    total_possible_results = entries.empty? ? 0 : entries[0].class.count_by_sql("SELECT FOUND_ROWS()")
    
    return entries, total_possible_results
  end
  
  def self.changes_feed(params)
    opts = {:feed_title => "Search - Annotation Changes"}
    opts.merge!(params)
    @feed = Feed.new(opts)
    entries, total_possible_results = AnnotationEvent.find_with_feed
    feed.serve(entries, total_possible_results)
  end
end