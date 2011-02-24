# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class FeedsController < ApplicationController
  skip_before_filter :personalize_location_and_institution, :except => :index
  
  layout 'pubsite'
  
  def index
    @right_column = false
    set_title('Feeds')
    set_titletag('eXtension - Feeds')
    @communities = Community.launched.all(:order => 'public_name')
  end

  def sitemap_index
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end
  
  def sitemap_communities
    @communities = Community.launched.all(:order => 'public_name')
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end
  
  def sitemap_pages
    @article_links = Page.find(:all).collect{ |article| article.id_and_link }
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end

  def sitemap_faq
    @faq_ids = Faq.find(:all).collect{ |faq| faq.id }
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end
  
  def sitemap_events
    @event_ids = Event.find(:all).collect{ |event| event.id }
    headers["Content-Type"] = "application/xml"    
    render :layout => false
  end
       
  def community
    return redirect_to(content_feed_url(:tags => params[:tags]), :status => 301)
  end
    
  def learn
    filteredparameters_list = [{:limit => {:default => AppConfig.configtable['default_feed_content_limit']}},:tags]
    filteredparams = ParamsFilter.new(filteredparameters_list,params)
    
    # limit over max? let's be pedantic
    if(filteredparams.limit > AppConfig.configtable['max_feed_content_limit'])
      return render_feed_error({:errormessage => "Requested limit of #{filteredparams.limit} is greater than the max allowed: #{AppConfig.configtable['max_feed_content_limit']}"})
    end
        
    # empty tags? - presume "all"
    if(filteredparams.tags.nil?)
       alltags = true
    else
       tag_operator = filteredparams._tags.taglist_operator      
       alltags = (filteredparams.tags.include?('all'))
       content_tags = filteredparams.tags
    end
    
    title = "eXtension Professional Development Sessions"
    if(alltags)
      title += " - All"
    else
      title += " - " + content_tags.join(" #{filteredparams._tags.taglist_operator} ")
    end
    
    if(alltags)
      sessions = LearnSession.limit(filteredparams.limit).all(:order => 'updated_at DESC')
    elsif(filteredparams._tags.taglist_operator == 'or')
      sessions = LearnSession.tagged_with_any_shared_tags(filteredparams.tags).limit(filteredparams.limit).all(:order => 'updated_at DESC')
    else
      sessions = LearnSession.tagged_with_shared_tags(filteredparams.tags).limit(filteredparams.limit).all(:order => 'updated_at DESC')
    end
    
    feed_meta = {:title => "Professional Development Sessions - eXtension", 
                 :subtitle => "eXtension published content",
                 :alternate => url_for(:controller => 'learn', :action => 'index', :only_path => false),
                 :updated_at => sessions.first.session_start}
    return render :text => atom_feed_from(sessions, feed_meta), :content_type => Mime::ATOM
  end
    
  def content
    filteredparameters_list = [:max_results,
                               {:limit => {:default => AppConfig.configtable['default_feed_content_limit']}},
                               :tags,
                               {:content_types => {:default => 'articles,faqs,events'}}]
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
    
    items = []      
    filteredparams.content_types.each do |content_type|
       case content_type
       when 'faqs'
          if(alltags)
             items += Faq.main_recent_list(:limit => limit)
          else
             items += Faq.main_recent_list(:content_tags => content_tags, :limit => limit, :tag_operator => tag_operator)
          end
       when 'articles'
          if(alltags)
             items += Page.main_recent_list(:limit => limit)
          else
             items += Page.main_recent_list(:content_tags => content_tags, :limit => limit, :tag_operator => tag_operator)
          end
       when 'events'
          # AppConfig.configtable['events_within_days'] should probably be a parameter
          # but we'll save that for another day
          if(alltags)
             items += Page.main_recent_event_list({:within_days => AppConfig.configtable['events_within_days'], :calendar_date => Date.today, :limit => limit})
          else
             items += Page.main_recent_event_list({:within_days => AppConfig.configtable['events_within_days'], :calendar_date => Date.today, :limit => limit, :content_tags => content_tags, :tag_operator => tag_operator})
          end 
       end
    end
    
    if(filteredparams.content_types.size > 1)
       # need to combine items - not using content_date_sort, because I don't want to modify
       # that at this time
       merged = {}
       tmparray = []
       items.each do |content|
          case content.class.name 
          when 'Article'
             merged[content.wiki_updated_at] = content
          when 'Faq'
             merged[content.heureka_published_at] = content
          when 'Event'
             merged[content.xcal_updated_at] = content
          end
       end
       tstamps = merged.keys.sort.reverse # sort by updated, descending
  		tstamps.each{ |key| tmparray << merged[key] }
  		@returnitems = tmparray.slice(0,limit)
    else
     	@returnitems = items
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
