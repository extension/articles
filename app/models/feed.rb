# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Feed < ActiveRecord::Base
  
  def self.columns() @columns ||= []; end      
  
  attr_reader :feed_meta
  attr_reader :gdata_params
  
  def initialize(opts={})
    
    default_url_options[:host] = AppConfig.get_url_host
    default_url_options[:protocol] = AppConfig.get_url_protocol
    if(default_port = AppConfig.get_url_port)
      default_url_options[:port] = default_port
    end
    
    feed_params = {
      :start_index_default => 1,
      :max_results_default => 50,
      # eX content did not exist in published fashion prior to 10/2006.
      :updated_min_default => Time.utc(2006,10),
      :updated_max_default => Time.utc(Time.now.year + 5, Time.now.month),
      :published_min_default => Time.utc(2006,10),
      :published_max_default => Time.utc(Time.now.year + 5, Time.now.month),
    }
    
    feed_params.merge!(opts)
    @filteredparams = FilterParams.new(feed_params)
    
    start_index = @filteredparams.start_index || feed_params[:start_index_default]
    max_results = @filteredparams.max_results || feed_params[:max_results_default]
    q = nil
    author = nil
    alt = nil
    
    updated_min = @filteredparams.updated_min || feed_params[:updated_min_default]
    updated_max = @filteredparams.updated_max || feed_params[:updated_max_default]
    published_min = @filteredparams.published_min || feed_params[:published_min_default]
    published_max = @filteredparams.published_max || feed_params[:published_max_default]
    category_array = nil
    
    if feed_params[:content_tags] && feed_params[:content_tags].length > 0
      category_array = feed_params[:content_tags]
      if category_array.length > 3
        raise ArgumentError
      end
    end
    
    @gdata_params = {:category_array => category_array,
                     :updated_min => updated_min,
                     :updated_max => updated_max,
                     :published_min => published_min,
                     :published_max => published_max,
                     :start_index => start_index,
                     :max_results => max_results}
    
   @feed_meta = {:title => feed_params[:feed_title], 
                :subtitle => "eXtension published content",
                :url => url_for(:only_path => false),
                :alt_url => url_for(:only_path => false, :controller => 'main', :action => 'index'),
                :start_index => start_index.to_s,
                :items_per_page => max_results.to_s}
  end
  
  def serve(objs, total_possible_results)
    @feed_meta[:total_results] = total_possible_results.to_s
    updated = objs.first.nil? ? Time.now.utc : objs.first.updated_at
    @feed_meta[:updated_at] = updated
    render_atom_feed_from(objs)
  end
  
  def render_atom_feed_from(objs) 
    render :text => atom_feed_from(objs), :content_type => Mime::ATOM
  end
  
  def atom_feed_from(objs)
    last_index = @feed_meta[:total_results] - @feed_meta[:items_per_page]
    last_index = 1 if last_index < 1
    
    first_index = 1
    
    next_index = @feed_meta[:start_index] + @feed_meta[:items_per_page]
    next_index = 0 if next_index > @feed_meta[:total_results]
    
    prev_index = @feed_meta[:start_index] - @feed_meta[:items_per_page]
    prev_index = 0 if prev_index < 1
    
    items_per_page = @feed_meta[:items_per_page].to_s
    
    feed = Atom::Feed.new do |f|
      f.title = @feed_meta[:title]
      f.subtitle = @feed_meta[:subtitle]
      f.links << Atom::Link.new(:type => "application/atom+xml", :rel => "self", :href => @feed_meta[:url])
      f.links << Atom::Link.new(:type => "text/html", :rel => "alternate", :href => "http://www.extension.org/")
      if first_index != last_index
        f.links << Atom::Link.new(:type => "application/atom+xml", :rel => "first", :href => @feed_meta[:url] + "?max_results=" + items_per_page + "&start_index=" + first_index.to_s)
      end
      if prev_index > 0
        f.links << Atom::Link.new(:type => "application/atom+xml", :rel => "prev", :href => @feed_meta[:url] + "?max_results=" + items_per_page + "&start_index=" + prev_index.to_s) 
      end
      if next_index > 0
        f.links << Atom::Link.new(:type => "application/atom+xml", :rel => "next", :href => @feed_meta[:url] + "?max_results=" + items_per_page + "&start_index=" + next_index.to_s)
      end
      f.links << Atom::Link.new(:type => "application/atom+xml", :rel => "last", :href => @feed_meta[:url] + "?max_results=" + items_per_page + "&start_index=" + last_index.to_s)
      f.updated = @feed_meta[:updated_at]
      f.authors << Atom::Person.new(:name => 'Contributors')
      f.id = @feed_meta[:url]
      for obj in objs
        f.entries << obj.to_atom_entry
      end
    end
    feed.to_xml
  end

end
