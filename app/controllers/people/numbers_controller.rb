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
    when 'institutions'
      @institution_communities = Community.find_all_by_entrytype(Community::INSTITUTION, @findoptions[:order]) 
    else
      @approved_communities = Community.find_all_by_entrytype(Community::APPROVED, @findoptions[:order]) 
      @usercontributed_communities = Community.find_all_by_entrytype(Community::USERCONTRIBUTED, @findoptions[:order]) 
      @institution_communities = Community.find_all_by_entrytype(Community::INSTITUTION, @findoptions[:order]) 
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
    @filteredparams = ParamsFilter.new([:communitytype, :connectiontype, :dateinterval],params)
    @findoptions = @filteredparams.findoptions
    @filterstring = @filteredparams.filter_string
    
    @communities = Community.filtered(@findoptions).displaylist
    @communitycounts = Community.userfilter_count(@findoptions)    
  end
  
  def community
    redirect_to :action => :summary, :community => params[:id]
  end
  
  # counts edit numbers, puts up a table
  def editors
    @filteredparams = ParamsFilter.new([:dateinterval,:activityapplication,:limit],params)
    baseoptions = {}
    baseoptions[:activityapplication] = @filteredparams.activityapplication
    baseoptions[:dateinterval] = @filteredparams.dateinterval
               
    
    # count logins
    filteroptions = {:dateinterval => @filteredparams.dateinterval, :activitycodes => Activity.activity_to_codes('login')}
    @logindata = Activity.filtered(filteroptions).count(:id,:group => 'user_id', :order => 'count_id DESC')
    # count edits
    filteroptions = baseoptions.merge({:activitycodes => Activity.activity_to_codes('edit')})
    @editdata = Activity.filtered(filteroptions).count(:id,:group => 'user_id', :order => 'count_id DESC')
    # count objects
    filteroptions = baseoptions.merge({:activitycodes => Activity.activity_to_codes('edit')})
    @objectdata = Activity.filtered(filteroptions).count(:activity_object_id,:distinct => true, :group => 'user_id', :order => 'count_activity_object_id DESC')
    
    # calculate thresholds
    @edit_percentages = {}
    running_total = 0
    @editdata.to_a.each_with_index do |(user_id,edits),index|
      if(index == (@editdata.size * 0.05).ceil-1)
        @edit_percentages['5%'] = {:users => index, :edits => running_total}
      elsif(index == (@editdata.size * 0.10).ceil-1)
        @edit_percentages['10%'] = {:users => index, :edits => running_total}
      elsif(index == (@editdata.size * 0.25).ceil-1)
        @edit_percentages['25%'] = {:users => index, :edits => running_total}
      end
      running_total += edits
    end
    
    @item_percentages = {}
    running_total = 0
    @objectdata.to_a.each_with_index do |(user_id,items),index|
      if(index == (@objectdata.size * 0.05).ceil-1)
        @item_percentages['5%'] = {:users => index, :edits => running_total}
      elsif(index == (@objectdata.size * 0.10).ceil-1)
        @item_percentages['10%'] = {:users => index, :edits => running_total}
      elsif(index == (@objectdata.size * 0.25).ceil-1)
        @item_percentages['25%'] = {:users => index, :edits => running_total}
      end
      running_total += items
    end
    
    # default to the 10% of the editors
    @limit = (@filteredparams.limit.nil?) ? @item_percentages['10%'][:users] : @filteredparams.limit
    
  end
  
end
