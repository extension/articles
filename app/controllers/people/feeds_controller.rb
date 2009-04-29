# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class FeedsController < ApplicationController
  include ActivityDisplayHelper
  include ApplicationHelper
  
  session :off, :except => [:index,:institutions, :locations, :positions,:applications]

  before_filter :signin_required, :only => [:index, :institutions, :locations, :positions,:applications]
  
  before_filter :validate_feedkey, :except => [:index,:institutions, :locations, :positions,:invalid,:applications]
  ATOM_FEED_LIMIT = 100  # TODO: paginated atom feeds!
  
  def index
    render(:layout => 'activity')
  end
  
  def institutions
    @displayfilter = params[:displayfilter].nil? ? 'all' : params[:displayfilter]
    
    case @displayfilter
    when 'system'
      @landgrant = Institution.find_all_by_entrytype(Institution::LANDGRANT, :order => 'name') 
      @state = Institution.find_all_by_entrytype(Institution::STATE, :order => 'name') 
      @federal = Institution.find_all_by_entrytype(Institution::FEDERAL, :order => 'name') 
    when 'landgrant'
      @landgrant = Institution.find_all_by_entrytype(Institution::LANDGRANT, :order => 'name') 
    when 'state'
      @state = Institution.find_all_by_entrytype(Institution::STATE, :order => 'name') 
    when 'federal'
      @federal = Institution.find_all_by_entrytype(Institution::FEDERAL, :order => 'name') 
    when 'usercontributed'
      @usercontributed = Institution.find_all_by_entrytype(Institution::USERCONTRIBUTED, :order => 'name') 
    else
      @filter = 'all'
      @landgrant = Institution.find_all_by_entrytype(Institution::LANDGRANT, :order => 'name') 
      @state = Institution.find_all_by_entrytype(Institution::STATE, :order => 'name') 
      @federal = Institution.find_all_by_entrytype(Institution::FEDERAL, :order => 'name') 
      @usercontributed = Institution.find_all_by_entrytype(Institution::USERCONTRIBUTED, :order => 'name') 
    end
    render(:layout => 'activity')
  end
  
  def locations
    @locations = Location.find(:all, :order => 'entrytype,name')
    render(:layout => 'activity')
  end
  
  def positions
    @positions = Position.find(:all, :order => 'entrytype,name') 
    render(:layout => 'activity')
  end  
    
  def applications
    @applications = ActivityApplication.find(:all, :order => 'displayname') 
    render(:layout => 'activity')
  end
  
  # feed generating methods
  
  def showuser
    begin
      @showuser = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      return show_invalid_feed_output({:errormsg => 'The specified user does not exist'})
    end      

    feedoptions = {}   
    feedoptions[:feedurl] = url_for(:action => :showuser, :id => @showuser.id, :feedkey => @feedkey)
    feedoptions[:communityview] = false
    feedoptions[:userview] = true
    feedoptions[:feedtitle] = "Activity for #{@showuser.fullname}"
    
    @activitylist = @showuser.activities.displayactivity.find(:all, :order => 'created_at DESC', :limit => ATOM_FEED_LIMIT)
    
    render :xml => activityfeed(@activitylist,feedoptions).to_xml    
        
  end
  
  def community
    # backwards compatibility
    communityactivity = params[:filter].nil? ? 'all' : params[:filter] 
    redirect_to :action => :list, :community => params[:id], :communityactivity => communityactivity, :feedkey => @feedkey, :status => 301
  end
  
  def communities
    # backwards compatibility
    communitytype = params[:filter].nil? ? 'all' : params[:filter] 
    redirect_to :action => :list, :community => params[:id], :communitytype => communitytype, :communityactivity => 'community', :feedkey => @feedkey, :status => 301
  end
  
  
  def institution
    # backwards compatibility
    redirect_to :action => :list, :institution => params[:id], :feedkey => @feedkey, :status => 301
  end
  
  def location
    # backwards compatibility
    redirect_to :action => :list, :location => params[:id], :feedkey => @feedkey, :status => 301
  end
  
  def position
    # backwards compatibility
    redirect_to :action => :list, :position => params[:id], :feedkey => @feedkey, :status => 301
  end
  
  def list
    @order = params[:order] || 'activities.created_at DESC'
    @findoptions = check_for_filters
    
    feedoptions = {}

    urlparams = {:controller => :feeds, :action => :list}
    urlparams.merge!(create_filter_params(@findoptions))
    if(@feedkey)
      urlparams.merge!({:feedkey => @feedkey})
    end
    
    feedoptions[:communityview] = params[:communityview] || false
    feedoptions[:userview] = params[:userview] || false
    feedoptions[:feedtitle] = "Activity Atom Feed #{filter_string(@findoptions.merge({:nolink => true}))}"
    

    @activitylist = Activity.filtered(@findoptions).find(:all, :limit => ATOM_FEED_LIMIT, :order => @order)
    render :xml => activityfeed(@activitylist,feedoptions).to_xml
  end      
    
  def application
    # backwards compatibility
    redirect_to :action => :list, :activityapplication => params[:id], :status => 301
  end  
    
  private
    def activityfeed(activitylist,feedoptions={})
      feed = Atom::Feed.new do |f|
        f.title = feedoptions[:feedtitle]
        f.links << Atom::Link.new(:rel => 'alternate', :type => 'text/html', :href => feedoptions[:alternate] || (request.protocol + request.host_with_port))
        f.links << Atom::Link.new(:rel => 'self', :type => 'application/atom+xml', :href => feedoptions[:self] || request.url)
        f.updated = (activitylist.first ? activitylist.first.created_at : Time.now.utc).xmlschema
        f.id = make_atom_feed_id()
        for activityitem in activitylist
          text = activity_to_s(activityitem,{:communityview => feedoptions[:communityview], :communityname => feedoptions[:communityname], :userview => feedoptions[:userview], :wantstitle => true})
          f.entries << Atom::Entry.new do |e|
            e.authors << Atom::Person.new(:name => activityitem.creator.fullname, :email => activityitem.creator.email)
            e.title = text[:title]
            e.links << Atom::Link.new(:rel => 'alternate', :type => 'text/html', :href => url_for(:action => :show, :id => activityitem.id))
            e.id = make_atom_entry_id(activityitem)
            e.updated = activityitem.created_at.xmlschema
            showuserinfo = feedoptions[:showuserinfo] || false
            if(showuserinfo)
              e.content = Atom::Content::Html.new(("<p>#{text[:body]}</p>"+render_to_string(:partial => 'common/showuser_short_profile', :locals => {:showuser => activityitem.user})))
            else
              e.content = Atom::Content::Html.new("<p>#{text[:body]}</p>")
            end
          end
        end
      end
    end
    
    def show_invalid_feed_output(feedoptions={})
      peoplebot = User.find(1)
      feed = Atom::Feed.new do |f|
        f.title = "eXtension Activity Feed Error"
        # TODO : link over to activity?
        f.links << Atom::Link.new(:rel => 'alternate', :type => 'text/html', :href => feedoptions[:alternate] || (request.protocol + request.host_with_port))
        f.links << Atom::Link.new(:rel => 'self', :type => 'application/atom+xml', :href => feedoptions[:self] || request.url)
        f.updated = Time.now.utc.xmlschema
        f.id = make_atom_feed_id()
        f.entries << Atom::Entry.new do |e|
          e.authors << Atom::Person.new(:name => peoplebot.fullname, :email => peoplebot.email)
          e.title = "eXtension Activity Feed Error"
          e.links << Atom::Link.new(:rel => 'alternate', :type => 'text/html', :href => feedoptions[:alternate] || (request.protocol + request.host_with_port))
          e.id = make_atom_entry_id("Invalid")
          e.updated = Time.now.utc.xmlschema
          errormsg = feedoptions[:errormsg] || "This private feed uses a key that is specific for your user account to retrieve the feed - and your key has changed or is invalid. Please visit the feeds page to resubscribe to this feed"
          e.content = Atom::Content::Html.new("<p>#{errormsg}</p>")
        end
      end

      render :xml => feed.to_xml    
    end

    private
    
    def validate_feedkey      
      @feedkey = params[:feedkey]
      if(!@feedkey.nil?)
        @currentuser = User.find_by_feedkey(@feedkey)
        if(!@currentuser.nil?)
          ActivityEvent.log_event(:event => ActivityEvent::FEEDREQUEST,:user => @currentuser,:eventdata => additionaldata_from_params(params))            
          return true
        end
      end
      
      ActivityEvent.log_event(:event => ActivityEvent::INVALIDFEEDREQUEST,:user => @currentuser,:eventdata => additionaldata_from_params(params))                  
      show_invalid_feed_output 
      return false
    end
    
    def make_atom_feed_id(schema_date=Time.now.year)
      "tag:#{request.host},#{schema_date}:#{request.request_uri.split(".")[0]}"
    end
    
    def make_atom_entry_id(obj,schema_date=Time.now.year)
      if(obj.class != "String")
        "tag:#{request.host},#{schema_date}:#{obj.class}/#{obj.id}"
      else
        "tag:#{request.host},#{schema_date}:#{obj}"
      end
    end
end