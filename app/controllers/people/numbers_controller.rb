# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class NumbersController < ApplicationController
  include ApplicationHelper
  include NumbersHelper

  layout 'people'
  before_filter :login_optional

  def index    
    redirect_to(:action => :summary)
  end
  
  def browsecommunities
    @filteredparams = FilterParams.new(params)
    @filteredparams.order=@filteredparams.order('name')
    @findoptions = @filteredparams.findoptions

    @displayfilter = @findoptions[:communitytype].nil? ? 'all' : @findoptions[:communitytype]
    @activitydisplay = params[:activitydisplay].nil? ? 'communityconnection' : params[:activitydisplay]

    # doesn't yet accept a filtered listing
    case @displayfilter
    when 'approved'
      @approved_communities = Community.find_all_by_entrytype(Community::APPROVED, @findoptions[:order]) 
    when 'usercontributed'
      @usercontributed_communities = Community.find_all_by_entrytype(Community::USERCONTRIBUTED, @findoptions[:order]) 
    else
      @approved_communities = Community.find_all_by_entrytype(Community::APPROVED, @findoptions[:order]) 
      @usercontributed_communities = Community.find_all_by_entrytype(Community::USERCONTRIBUTED, @findoptions[:order]) 
    end
  end
  
  def browseinstitutions
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
  end
  
  def browse
    @browselist = params[:browselist].nil? ? 'none' : params[:browselist]
    if(@browselist == 'none')
      return(redirect_to(:action => 'index'))
    end
    
    case @browselist
    when 'communities'
      communitytype = params[:communitytype].nil? ? 'all' : params[:communitytype]
      return(redirect_to(:action => 'browsecommunities', :communitytype => communitytype))
    when 'institutions'
      displayfilter = params[:displayfilter].nil? ? 'all' : params[:displayfilter]
      return(redirect_to(:action => 'browseinstitutions', :displayfilter => displayfilter))
    when 'locations'
      @page_title = "Numbers - Browse by Location"
      @itemlist = Location.find(:all, :order => 'entrytype,name')
    when 'positions'
      @page_title = "Numbers - Browse by Position"
      @itemlist = Position.find(:all, :order => 'entrytype,name')
    when 'applications'
      @page_title = "Numbers - Browse by Application"
      @itemlist = ActivityApplication.reportable.find(:all, :order => 'applicationtype,displayname') 
    else
      return(redirect_to(:action => 'index'))
    end        
  end
  
  def institutions
    @displayfilter = params[:displayfilter].nil? ? 'all' : params[:displayfilter]
    @filteredparams = FilterParams.new(params)
    @findoptions = @filteredparams.findoptions
    
    
    case @displayfilter
    when 'system'
      @landgrant = Institution.filtered(@findoptions.merge({:entrytype => Institution::LANDGRANT})).displaylist
      @state = Institution.filtered(@findoptions.merge({:entrytype => Institution::STATE})).displaylist 
      @federal = Institution.filtered(@findoptions.merge({:entrytype => Institution::FEDERAL})).displaylist
    when 'landgrant'
      @landgrant = Institution.filtered(@findoptions.merge({:entrytype => Institution::LANDGRANT})).displaylist
    when 'state'
      @state = Institution.filtered(@findoptions.merge({:entrytype => Institution::STATE})).displaylist 
    when 'federal'
      @federal = Institution.filtered(@findoptions.merge({:entrytype => Institution::FEDERAL})).displaylist
    when 'usercontributed'
      @usercontributed = Institution.filtered(@findoptions.merge({:entrytype => Institution::USERCONTRIBUTED})).displaylist
    else
      @filter = 'all'
      @landgrant = Institution.filtered(@findoptions.merge({:entrytype => Institution::LANDGRANT})).displaylist
      @state = Institution.filtered(@findoptions.merge({:entrytype => Institution::STATE})).displaylist 
      @federal = Institution.filtered(@findoptions.merge({:entrytype => Institution::FEDERAL})).displaylist
      @usercontributed = Institution.filtered(@findoptions.merge({:entrytype => Institution::USERCONTRIBUTED})).displaylist
    end
    
    @institutioncounts = Institution.userfilter_count(@findoptions)
    
  end
  
  def institution
    # backwards compatibility
    redirect_to :action => :summary, :institution => params[:id]
  end
  


  def locations
    @filteredparams = FilterParams.new(params)
    @findoptions = @filteredparams.findoptions
    @locations = Location.filtered(@findoptions).displaylist
    @locationcounts = Location.userfilter_count(@findoptions)
  end
  
  def location
    # backwards compatibility
    redirect_to :action => :summary, :location => params[:id]
  end
  
  def positions
    @filteredparams = FilterParams.new(params)
    @findoptions = @filteredparams.findoptions
    @positions = Position.filtered(@findoptions).displaylist
    @positioncounts = Position.userfilter_count(@findoptions)
  end
  
  def summary
    @filteredparams = FilterParams.new(params)
    
    forcecacheupdate = params[:forcecacheupdate].nil? ? false : (params[:forcecacheupdate] == 'true')
    baseoptions = {:forcecacheupdate => forcecacheupdate}

    if(params[:community])
      begin
        @community = Community.find(params[:community])
        baseoptions[:filtercommunity] = @community
      rescue ActiveRecord::RecordNotFound  
        flash[:error] = 'That community does not exist'  
        return(redirect_to(:action => 'index'))
      end
    end
    
    totaloptions = baseoptions.merge({:findoptions => @filteredparams.findoptions})
    @total = NumberSummary.new(totaloptions)
            
    lastmonthoptions = baseoptions.merge({:findoptions => @filteredparams.findoptions.merge({:dateinterval => 'withinlastmonth'})})
    lastmonthoptions[:summarydateinterval] = 'withinlastmonth'
    @lastmonth = NumberSummary.new(lastmonthoptions)
  end 
  
  def position
    # backwards compatibility
    redirect_to :action => :summary, :position => params[:id]
  end
  

  def communities
    @filteredparams = FilterParams.new(params)
    @findoptions = @filteredparams.findoptions
    @communities = Community.filtered(@findoptions).displaylist
    @communitycounts = Community.userfilter_count(@findoptions)    
  end
  
  def community
    redirect_to :action => :summary, :community => params[:id]
  end
  
end
