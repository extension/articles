# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class People::CommunitiesController < ApplicationController
  include ApplicationHelper
  include LoggingExtensions
  
  layout 'people'
  before_filter :login_required
  before_filter :check_purgatory

  # GET /communities
  def index

    if(@currentuser.tags.count > 0) 
      @relevant_communities = @currentuser.relevant_community_scores
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  
  def modify_user_connection
    # assumes @currentuser
    begin
      @community = Community.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      # need to render something
    end
    
    # leadership check
    if(!@currentuser.is_community_leader?(@community) and !admin_mode?)
      flash[:warning] = "You are not a leader for this community."
      return(redirect_to(community_url(@community.id)))
    end
      
    begin
      @showuser = User.find_by_id(params[:userid])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'Unable to find user.'
      return(redirect_to(community_url(@community.id)))
    end    
    
    @ismemberchange = true
    @connectaction = params[:connectaction].nil? ? 'none' :  params[:connectaction]
    case @connectaction
    when 'removeleader'
      @community.remove_user_from_leadership(@showuser,@currentuser)
    when 'removemember'
      @community.remove_user_from_membership(@showuser,@currentuser)
    when 'addmember'
      @community.add_user_to_membership(@showuser,@currentuser)
    when 'addleader'
      @community.add_user_to_leadership(@showuser,@currentuser)
    when 'rescindinvitation'
      @community.rescind_user_invitation(@showuser,@currentuser)
    when 'invitemember'
      @community.invite_user(@showuser,false,@currentuser)
    when 'inviteleader'
      @community.invite_user(@showuser,true,@currentuser)
    when 'invitereminder'      
      Activity.log_activity(:user => @showuser,:creator => @currentuser, :community => @community, :activitycode => Activity::COMMUNITY_INVITEREMINDER , :appname => 'local')
      Notification.create(:notifytype => Notification::COMMUNITY_LEADER_INVITEREMINDER, :user => @showuser, :creator => @currentuser, :community => @community)
    else
      # do nothing
    end
    
    respond_to do |format|
      format.js
    end
  end
  

  
  def change_my_connection
    # assumes @currentuser
    begin
      @community = Community.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      # need to render something
    end
    
    @ismemberchange = true
    case params[:connectaction]
    when 'leave'
      @currentuser.leave_community(@community)
    when 'join'
      if(@community.memberfilter == Community::OPEN)
        @currentuser.join_community(@community)
      elsif(@community.memberfilter == Community::MODERATED)
        @ismemberchange = false
        @currentuser.wantstojoin_community(@community)
      else
        # do nothing
      end
    when 'interest'
      @currentuser.interest_community(@community)
    when 'nointerest'
      @currentuser.nointerest_community(@community)
    when 'accept'
      @currentuser.accept_community_invitation(@community)
    when 'decline'
      @currentuser.decline_community_invitation(@community)
    else
      # do nothing
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def change_my_notification
    # assumes @currentuser
    begin
      @community = Community.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      # need to render something
    end
    
    if(params[:notification] && params[:notification] == 'yesiwill' )
       @currentuser.update_notification_for_community(@community,true)
       UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "turned on community notifications for #{@community.name}")   
     else
      @currentuser.update_notification_for_community(@community,false)
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "turned off community notifications for #{@community.name}")
    end
    
    respond_to do |format|
      format.js
    end
  end  

  # GET /communities/1
  
  def show
    @community = Community.find_by_shortname_or_id(params[:id])
    if(@community.nil?)  
      flash[:error] = 'That community does not exist'  
      return(redirect_to(:action => 'index'))
    end      
        
    @am_i_leader = @currentuser.is_community_leader?(@community)   
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  def downloadlists
    @filteredparams = FilterParams.new(params)
    if(@filteredparams.dateinterval.nil?)
      @filteredparams.dateinterval = 'all'
    end
    if(@filteredparams.communitytype.nil?)
      @filteredparams.communitytype = 'approved'
    end    
    @findoptions = @filteredparams.findoptions
    
    @communities = Community.filtered(@findoptions).displaylist
    @communitycounts = Community.userfilter_count(@findoptions)
  end
  
  def userlist
    begin
      @community = Community.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'That community does not exist'  
      return(redirect_to(:action => 'index'))
    end
    @am_i_leader = @currentuser.is_community_leader?(@community)   
    
    @filteredparams = FilterParams.new(params)
    @filteredparams.community = @community.id
    if(@filteredparams.connectiontype.nil?)
      @filteredparams.connectiontype = 'joined'
    end

    if(@filteredparams.dateinterval.nil?)
      @filteredparams.dateinterval = 'all'
    end

    @findoptions = @filteredparams.findoptions

    
    
    @page_title = @community.name + ': ' + Communityconnection::TYPES[@filteredparams.connectiontype]
        # download check    
    if(!params[:download].nil? and params[:download] == 'csv')
      @findoptions.merge!(:paginate => false)
      reportusers = User.filtered(@findoptions).ordered(@filteredparams.order).all
      csvfilename =  @page_title.tr(' ','_').gsub('\W','').downcase
      return community_csvuserlist(reportusers,csvfilename,@community)
    else
      @userlist = User.filtered(@findoptions).ordered(@filteredparams.order).paginate(:all,:page => params[:page])
      if((@userlist.length) > 0)
        urloptions = @findoptions.merge(:id => params[:id], :download => 'csv')
        @csvreporturl = CGI.escapeHTML(userlist_community_url(urloptions))
      end
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @community }      
    end
      
  end
  
  # GET /communities/new
  # GET /communities/new.xml
  def new
    if params[:community]
      @community = Community.new(params[:community])
    else
      @community = Community.new
    end
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /communities/1/edit
  def edit
    @community = Community.find(params[:id])
    if(!@currentuser.is_community_leader?(@community) and !admin_mode?)
      flash[:warning] = "You are not a leader for this community."
      return(redirect_to(community_url(@community.id)))
    end
  end
  
  def editlists
    @community = Community.find_by_shortname_or_id(params[:id])
    if(@community.nil?)  
      flash[:error] = 'That community does not exist'  
      return(redirect_to(:action => 'index'))
    end
    
    if(!@currentuser.is_community_leader?(@community) and !admin_mode?)
      flash[:warning] = "You are not a leader for this community."
      return(redirect_to(community_url(@community.id)))
    end
        
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def xhr_create_list
    # hardcoded 
    allowedtypes = ['leaders','joined','interested']
    @community = Community.find_by_shortname_or_id(params[:communityid])
    @errors = nil
    if(!@currentuser.is_community_leader?(@community) and !admin_mode?)
      @errors ="You are not a leader for this community."
    else    
      @listtype = params[:listtype]
      if(!@listtype.nil?)
        if(allowedtypes.include?(@listtype))
          @listname = params["#{@listtype}-listname"].downcase
          @list_form_value = @listname # convenience for filling in the form on errors
          if(@listname =~ /^[a-zA-Z0-9-]+$/)
            existinglist = List.find_by_name(@listname)
            if(existinglist.nil?)
              @community.create_or_connect_to_list({:connectiontype => @listtype, :name => @listname, :dropforeignsubscriptions => true, :dropunconnected => true})
              @list_form_value = ''
              log_user_activity(:activitycode => Activity::COMMUNITY_CREATED_LIST,:user => @currentuser,:community => @community,:appname => 'local')   
            else
              if(!existinglist.community.nil?)
                @errors = "A list with that name already exists, connected to the #{link_to_community(existinglist.community)} community."
              else
                @errors = "A list with that name already exists."
              end
            end
          else
            @errors = "The list name must not contain spaces or special characters. Only [A-Z], [0-9], and '-' are allowed in the mailing list name."
          end
        else
          @errors = "#{@listtype} is not an allowed mailing list type"
        end
      end
    end
    
    respond_to do |format|
      format.js
    end
  end

  # POST /communities
  # POST /communities.xml
  def create
    @community = Community.new(params[:community])
    
    # force entrytype to be user created unless admin
    if(!admin_mode?)
      @community.entrytype = Community::USERCONTRIBUTED
    end
    
    @community.creator = @currentuser

    respond_to do |format|
      if @community.save
        if(!admin_mode?)
          @community.creator.join_community_as_leader(@community)
        end
        # tags
        @community.tag_myself_with_peoplebot_tags(params[:tag_list].strip)        
        flash[:notice] = 'Community was successfully created.'
        UserEvent.log_event(:etype => UserEvent::COMMUNITY,:user => @currentuser,:description => "created the #{@community.name} community")   
        log_user_activity(:activitycode => Activity::CREATED_COMMUNITY,:user => @currentuser,:community => @community,:appname => 'local')   
        format.html { redirect_to(@community) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /communities/1
  # PUT /communities/1.xml
  def update
    @community = Community.find(params[:id])
    if(!@currentuser.is_community_leader?(@community) and !admin_mode?)
      flash[:warning] = "You are not a leader for this community."
      return(redirect_to(community_url(@community.id)))
    end
    
    respond_to do |format|
      if @community.update_attributes(params[:community])
        @community.tag_myself_with_peoplebot_tags(params[:tag_list].strip)        
        flash[:notice] = 'Community was successfully updated.'
        log_user_activity(:activitycode => Activity::COMMUNITY_UPDATE_INFORMATION,:user => @currentuser,:community => @community,:appname => 'local')   
        format.html { redirect_to(@community) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  def describe
    @community = Community.find(params[:id])
    if(!@currentuser.communityjoins.include?(@community))
      flash[:warning] = "You are not a leader or member within this community."
      return(redirect_to(community_url(@community.id)))
    end
    
    if request.post?
      @community.update_user_tags(params[:tag_list].strip,@currentuser)              
      log_user_activity(:activitycode => Activity::COMMUNITY_TAGGED,:user => @currentuser,:community => @community,:appname => 'local')   
      flash[:notice] = 'Your tags for this community were successfully updated.'
      return redirect_to(@community)
    end
  end

  # DELETE /communities/1
  # DELETE /communities/1.xml
  def destroy
    @community = Community.find(params[:id])
    @community.destroy

    respond_to do |format|
      format.html { redirect_to(communities_url) }
      format.xml  { head :ok }
    end
  end
  
  
  def findcommunity
    if (params[:id].nil? or params[:id].empty?)
      flash[:warning] = "Empty search term"
      redirect_to :action => 'index'
    else    
      
      @communitylist = Community.search({:order => 'name', :limit => 10, :searchterm => params[:id], :page => params[:page], :paginate => true})
          
      if @communitylist.nil? || @communitylist.length == 0
        flash[:warning] = "No community was found that matches your search term"
        redirect_to :action => 'index'
      else
        if @communitylist.length == 1
          redirect_to :action => :show, :id => @communitylist[0].id
        end
      end
    end
  end  
  
  def newest 
    @communitylist = Community.paginate(:all,:order => 'created_at DESC', :page => params[:page])
    @page_title = "Newest Communities"
    respond_to do |format|
      format.html { render :template => "communities/communitylist" }
    end
  end 
  
  def mine 
    @communitylist = @currentuser.communities.paginate(:all,:order => 'created_at DESC', :page => params[:page])
    @page_title = "Your Communities"
    respond_to do |format|
      format.html { render :template => "communities/communitylist" }
    end
  end
    
  def browse 
    @communitylist = Community.paginate(:all,:order => 'name ASC', :page => params[:page])
    @page_title = "All Communities"
    respond_to do |format|
      format.html { render :template => "communities/communitylist" }
    end
  end
  
  def tags
    taglist = params[:taglist].strip
    @communitylist = Community.tagged_with_any(Community.tag_cast_to_string(taglist),{:getfrequency => true,:minweight => 2}).uniq
    @page_title = "Communities tagged with <em>#{taglist}</em>"
    respond_to do |format|
      format.html
    end
  end     
  
  def xhrfinduser
    begin
      @community = Community.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      # uh - do something?
    end
    if (params[:searchterm] and params[:searchterm].strip != "" and params[:searchterm].strip.length >= 3 )
      @searchterm = params[:searchterm]
      @userlist = User.searchcolleagues({:order => 'last_name,first_name', :limit => 11, :searchterm => params[:searchterm]})
    end    
    
    respond_to do |format|
      format.js
    end
  end
  
  def invite
    begin
      @community = Community.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'That community does not exist'  
      return(redirect_to(:action => 'index'))
    end
  
    if (params[:searchterm] and params[:searchterm].strip != "" and params[:searchterm].strip.length >= 3 )
      @searchterm = params[:searchterm]
      @userlist = User.searchcolleagues({:order => 'last_name,first_name', :limit => 11, :searchterm => params[:searchterm]})
    end   

    respond_to do |format|
      format.html
    end
    
  end
  
  def inviteuser
    # assumes @currentuser
    begin
      @community = Community.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      # need to render something
    end

    # leadership check  
    if((!@currentuser.is_community_leader?(@community) and !admin_mode?) and (!(@currentuser.communityopenjoins.include?(@community))))
      flash[:warning] = "You are not able to invite others to this community."
      return(redirect_to(community_url(@community.id)))
    end

    begin
      @showuser = User.find_by_id(params[:userid])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'Unable to find user.'
      return(redirect_to(community_url(@community.id)))
    end    

    inviteasleader = (!params[:inviteasleader].nil? and params[:inviteasleader] == 'yesinviteleader')
    if((!@currentuser.is_community_leader?(@community) and !admin_mode?))
      # for inviteasleader to be false
      inviteasleader = false
    end
    @community.invite_user(@showuser,inviteasleader,@currentuser)
  
    respond_to do |format|
      format.js
    end
  end
  
  
  #----------------------------------
  # protected functions
  #----------------------------------
  protected

  def community_csvuserlist(userlist,filename,community)
    @userlist = userlist
    @community = community
    response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
    response.headers['Content-Disposition'] = 'attachment; filename='+filename+'.csv'
    render(:template => 'communities/community_csvuserlist', :layout => false)
  end
  

  
end
