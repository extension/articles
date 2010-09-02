# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class People::ListsController < ApplicationController
  layout 'people'
  before_filter :login_required, :check_purgatory, :except => [:show, :postinghelp, :about]
  before_filter :login_optional, :only => [:show, :postinghelp, :about]
  before_filter :set_user_time_zone
  
  def postinghelp
  end
  
  def about
  end
  
  def showpost
    begin
      @listpost = ListPost.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'That list posting does not exist'  
      return(redirect_to(:action => 'index'))
    end 
  end
  
  def posts
    if(params[:id] != 'all')
      begin
        @list = List.find_by_name_or_id(params[:id])
      rescue ActiveRecord::RecordNotFound  
        flash[:error] = 'That list does not exist'  
        return(redirect_to(:action => 'index'))
      end
      @showall = false
      @listposts = @list.list_posts.paginate(:all, :order => 'posted_at DESC', :page => params[:page])
    else
      @showall = true
      @listposts = ListPost.paginate(:all, :order => 'posted_at DESC', :page => params[:page])
    end
  end
  
  def postactivity
    # stats
    @stats ={:lastweek => {}, :lastweek => {}}
    
    @stats[:lastweek] = ListPost.get_posting_stats('lastweek')
    @stats[:lastmonth] = ListPost.get_posting_stats('lastmonth')
    
    @inactive = List.inactive('lastmonth')
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  
  def show
    @list = List.find_by_name_or_id(params[:id])
    if(@list.nil?)  
      flash[:error] = 'That list does not exist'  
      return(redirect_to(:action => 'index'))
    end
    
    # currentuser is subscribed?
    if(!@currentuser.nil?)
      @mylistsubscription = @currentuser.get_subscription_to_list(@list)
      # currentuser is list owner?
      @mylistownership = @currentuser.get_ownership_for_list(@list)
    end
    
    # stats
    @stats ={:lastweek => {}, :lastweek => {}}
    
    @stats[:lastweek] = @list.get_posting_stats('lastweek')
    @stats[:lastmonth] = @list.get_posting_stats('lastmonth')
    

    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  def change_my_moderation
    # assumes @currentuser
    begin
      @list = List.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      # need to render something
    end
    
    if(params[:moderationaction] && params[:moderationaction] == 'moderator' )
       @mylistownership = @currentuser.update_moderation_for_list(@list,true)
       UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "set moderation for #{@list.name}")   
    elsif(params[:moderationaction] && params[:moderationaction] == 'nomoderator' )
       @mylistownership = @currentuser.update_moderation_for_list(@list,false)
       UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "removed moderation for #{@list.name}")
    end
    
    @mylistsubscription = @currentuser.get_subscription_to_list(@list)
    
    respond_to do |format|
      format.js
    end
  end
  
  def change_my_subscription
    # assumes @currentuser
    begin
      @list = List.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      # need to render something
    end
    
    if(params[:subscribeaction] && params[:subscribeaction] == 'unsubscribe' )
      @currentuser.get_subscription_to_list(@list).destroy
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "unsubscribed from #{@list.name}")
      @mylistsubscription = nil
    elsif(params[:subscribeaction] && params[:subscribeaction] == 'optin' )
       @mylistsubscription = @currentuser.update_notification_for_list(@list,true)
       UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "opted-in to #{@list.name}")   
    elsif(params[:subscribeaction] && params[:subscribeaction] == 'optout' )
       @mylistsubscription = @currentuser.update_notification_for_list(@list,false)
       UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "opted-out from #{@list.name}")
    end
    
    @mylistownership = @currentuser.get_ownership_for_list(@list)
    
    respond_to do |format|
      format.js
    end
  end
  
  def subscriptionlist
    begin
      @list = List.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'That list does not exist'  
      return(redirect_to(:action => 'index'))
    end
    
    @am_i_owner = @currentuser.listownerships.include?(@list)   
    
    allowedtypes = List::SUBSCRIPTIONTYPES.keys
    @listtype = !params[:type].nil? ? params[:type] : 'subscribers'
    
    if(!allowedtypes.include?(@listtype))
      @listtype = 'subscribers'
    end
    
    if(@listtype != 'noidsubscribers')
      findopts = {:order => 'users.last_name'}
    else
      findopts = {:order => 'email'}
    end
    
    #findopts.merge!({:include => :user})
    
    @page_title = @list.name + ': ' + List::SUBSCRIPTIONTYPES[@listtype]
    if(@listtype == 'unconnected')
      findopts[:page] = params[:page]
      @subscriptionlist = @list.list_subscriptions.filteredsubscribers(@list.connectedusers,false).paginate(:all, findopts);
    else
      findopts[:page] = params[:page]
      @subscriptionlist = @list.list_subscriptions.send(@listtype).paginate(:all, findopts);
    end
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  def ownerlist
    begin
      @list = List.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'That list does not exist'  
      return(redirect_to(:action => 'index'))
    end
    
    @am_i_owner = @currentuser.listownerships.include?(@list)   
    
    allowedtypes = List::OWNERTYPES.keys
    @listtype = !params[:type].nil? ? params[:type] : 'idowners'
    
    if(!allowedtypes.include?(@listtype))
      @listtype = 'idowners'
    end
    
    if(@listtype != 'noidowners')
      findopts = {:order => 'users.last_name'}
    else
      findopts = {:order => 'email'}
    end
    
    #findopts.merge!({:include => :user})
    
    @page_title = @list.name + ': ' + List::OWNERTYPES[@listtype]
    findopts[:page] = params[:page]
    @ownerlist = @list.list_owners.send(@listtype).paginate(:all, findopts);
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  def all
    @listoflists = List.paginate(:all, :order => "name", :page => params[:page])
  end
    
  def managed
    @listoflists = List.paginate(:all, :conditions => {:managed => true}, :order => "name", :page => params[:page])
  end
  
  def nonmanaged
    @listoflists = List.paginate(:all, :conditions => {:managed => false}, :order => "name", :page => params[:page])
  end
end