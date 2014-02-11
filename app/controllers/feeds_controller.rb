# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

class FeedsController < ApplicationController
  skip_before_filter :personalize_location_and_institution, :except => :index
  layout 'frontporch'
  
  def index
    @right_column = false
    set_title('Feeds')
    set_title('eXtension - Feeds')
    @communities = PublishingCommunity.launched.all(:order => 'public_name')
    @learn_event_widget_url = "https://learn.extension.org/widgets/front_porch.js"
  end
 
  def community
    return redirect_to(content_feed_url(:tags => params[:tags]), :status => 301)
  end
        
  def content
    begin
    filteredparameters_list = [:max_results,
                               {:limit => {:default => AppConfig.configtable['default_feed_content_limit']}},
                               :tags,
                               {:content_types => {:default => 'articles,news,faqs,events'}}]
    filteredparams = ParamsFilter.new(filteredparameters_list,params)
    
    
    if(!filteredparams.max_results.nil?)
      limit = filteredparams.max_results
    else
      limit = filteredparams.limit
    end
    
    # limit over max? let's be pedantic
    if(limit > AppConfig.configtable['max_feed_content_limit'])
      return render_feed_error({:errormessage => "Requested limit of #{limit} is greater than the max allowed: #{AppConfig.configtable['max_feed_content_limit']}"})
    end
    
    
    # empty tags? - presume "all"
    if(filteredparams.tags.nil?)
       alltags = true
       content_tags = ['all']
    else
       tag_operator = filteredparams._tags.taglist_operator      
       alltags = (filteredparams.tags.include?('all'))
       if(alltags)
         content_tags = ['all']
       else  
         content_tags = filteredparams.tags
       end
    end
    
    datatypes = []
    filteredparams.content_types.each do |content_type|
      case content_type
      when 'faqs'
        datatypes << 'Faq'
      when 'articles'
        datatypes << 'Article'
      when 'events'
        datatypes << 'Event'
      when 'news'
        datatypes << 'News'
      end
    end
    
    if(alltags)
       @returnitems = Page.recent_content(:datatypes => datatypes, :limit => limit)
    else
       @returnitems = Page.recent_content(:datatypes => datatypes, :content_tags => content_tags, :limit => limit, :tag_operator => tag_operator, :within_days => AppConfig.configtable['events_within_days'])
    end
              
    title = "eXtension #{filteredparams.content_types.map{|name| name.capitalize}.join(',')}"
    if(alltags)
      title += "- All"
    else
      title += "- " + content_tags.join(" #{filteredparams._tags.taglist_operator} ")
    end

      
    feed_meta = {:title => title, 
                 :subtitle => "eXtension published content",
                 :updated_at => @returnitems.blank? ? Time.zone.now : @returnitems.first.updated_at}
    return render :text => atom_feed_from(@returnitems, feed_meta), :content_type => Mime::ATOM
  rescue
    do_404
  end
  
  end
      
  private
  
  def render_feed_error(feedoptions={})
    feed = Atom::Feed.new do |f|
      f.title = "eXtension Feed Error"
      # TODO : link over to activity?
      f.links << Atom::Link.new(:rel => 'alternate', :type => 'text/html', :href => feedoptions[:alternate] || (request.protocol + request.host_with_port))
      f.links << Atom::Link.new(:rel => 'self', :type => 'application/atom+xml', :href => feedoptions[:self] || request.url)
      f.updated = Time.now.utc.xmlschema
      f.id = make_atom_feed_id()
      f.entries << Atom::Entry.new do |e|
        e.authors << Atom::Person.new(:name => 'eXtension', :email => 'webmaster@extension.org')
        e.title = "eXtension Feed Error"
        e.links << Atom::Link.new(:rel => 'alternate', :type => 'text/html', :href => feedoptions[:alternate] || (request.protocol + request.host_with_port))
        e.id = make_atom_entry_id("Invalid")
        e.updated = Time.now.utc.xmlschema
        errormsg = feedoptions[:errormessage] || "An error occurred with the feed you requested."
        e.content = Atom::Content::Html.new("<p>#{errormsg}</p>")
      end
    end

    render :xml => feed.to_xml    
  end

  
  def atom_feed_from(entries, meta)
    feed = Atom::Feed.new do |f|
      f.title = meta[:title]
      f.subtitle = meta[:subtitle]
      f.links << Atom::Link.new(:type => "application/atom+xml", :rel => "self", :href => meta[:self] || request.url)
      f.links << Atom::Link.new(:type => "text/html", :rel => "alternate", :href => meta[:alternate] || url_for(:only_path => false, :controller => 'main', :action => 'index'))
      f.updated = meta[:updated_at]
      f.authors << Atom::Person.new(:name => 'Contributors')
      f.id = make_atom_feed_id()
      for entry in entries
        f.entries << entry.to_atom_entry
      end
    end
    feed.to_xml
  end
  
  def make_atom_feed_id(schema_date=Time.now.year)
    "tag:#{request.host},#{schema_date}:#{request.path}"
  end
  
  def make_atom_entry_id(obj,schema_date=Time.now.year)
    if(obj.class != "String")
      "tag:#{request.host},#{schema_date}:#{obj.class}/#{obj.id}"
    else
      "tag:#{request.host},#{schema_date}:#{obj}"
    end
  end
end
