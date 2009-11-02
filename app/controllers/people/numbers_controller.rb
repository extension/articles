# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class People::NumbersController < ApplicationController
  layout 'people'
  before_filter :login_optional

  def index    
    redirect_to(:action => :summary)
  end
  
  def browsecommunities
    @filteredparams = FilterParams.new(params)
    @filteredparams.order=@filteredparams.order('name')
    @findoptions = @filteredparams.findoptions
    @filterstring = @filteredparams.filter_string
    

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
  
  def locations
    @filteredparams = FilterParams.new(params)
    @filterstring = @filteredparams.filter_string
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
    @filterstring = @filteredparams.filter_string
    
    if(params[:community] and @filteredparams.community.nil?)
      flash[:error] = 'That community does not exist'  
      return(redirect_to(:action => 'index'))
    else
      baseoptions = {:filtercommunity => @filteredparams.community, :forcecacheupdate => @filteredparams.forcecacheupdate}
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
    @filterstring = @filteredparams.filter_string
    
    @communities = Community.filtered(@findoptions).displaylist
    @communitycounts = Community.userfilter_count(@findoptions)    
  end
  
  def community
    redirect_to :action => :summary, :community => params[:id]
  end
  
end
