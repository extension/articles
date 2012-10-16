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
    filteredparams_list = [{:order => {:default => 'name'}},
                           {:communitytype => {:default => 'all'}}]
    @filteredparams = ParamsFilter.new(filteredparams_list,params)
    @findoptions = @filteredparams.findoptions
    @filterstring = @filteredparams.filter_string
    

    @displayfilter = @filteredparams.communitytype

    # doesn't yet accept a filtered listing
    case @displayfilter
    when 'approved'
      @approved_communities = Community.find_all_by_entrytype(Community::APPROVED, :order => @filteredparams.order) 
    when 'usercontributed'
      @usercontributed_communities = Community.find_all_by_entrytype(Community::USERCONTRIBUTED, :order => @filteredparams.order) 
    when 'institutions'
      @institution_communities = Community.find_all_by_entrytype(Community::INSTITUTION, :order => @filteredparams.order) 
    else
      @approved_communities = Community.find_all_by_entrytype(Community::APPROVED, :order => @filteredparams.order) 
      @usercontributed_communities = Community.find_all_by_entrytype(Community::USERCONTRIBUTED, :order => @filteredparams.order) 
      @institution_communities = Community.find_all_by_entrytype(Community::INSTITUTION, :order => @filteredparams.order) 
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
    @filteredparams = ParamsFilter.new(Location.userfilteredparameters,params)
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
    @filteredparams = ParamsFilter.new(Position.userfilteredparameters,params)    
    @findoptions = @filteredparams.findoptions
    @positions = Position.filtered(@findoptions).displaylist
    @positioncounts = Position.userfilter_count(@findoptions)
  end
  
  def summary
    filteredparameters_list = [:community,:forcecacheupdate]
    filteredparameters_list += Activity.filteredparameters
    @filteredparams = ParamsFilter.new(filteredparameters_list,params)
    @filterstring = @filteredparams.filter_string
    
    if(@filteredparams.community? and @filteredparams.community.nil?)
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
    @filteredparams = ParamsFilter.new([:communitytype, :connectiontype, :dateinterval],params)
    @findoptions = @filteredparams.findoptions
    @filterstring = @filteredparams.filter_string
    
    @communities = Community.filtered(@findoptions).displaylist
    @communitycounts = Community.userfilter_count(@findoptions)    
  end
  
  def community
    redirect_to :action => :summary, :community => params[:id]
  end
  
  def editors
    data_url = "#{AppConfig.configtable['data_site']}nodes"
    return redirect_to(data_url, :status => :moved_permanently)
  end
  
end
