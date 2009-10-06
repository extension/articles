# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'hpricot'

class People::ColleaguesController < ApplicationController
  layout 'people'  
  before_filter :login_required
  before_filter :check_purgatory
  
  def communityinterest
    # convenience method to do redirection to new communities controller
    return redirect_to(:controller => '/people/communities', :action => :show, :id => params[:id])
  end
  
  def communitymembership
    # convenience method to do redirection to new communities controller
    return redirect_to(:controller => '/people/communities', :action => :show, :id => params[:id])
  end
  
  def index
    @vouchwaiting = User.count(:conditions => ["vouched = 0 AND retired = 0 AND emailconfirmed = 1"])
  end
    
  def invite
    return redirect_to(new_people_invitation_url)
  end
  
  
  def vouch
    if not params[:extensionid].nil?
      @showuser = User.find_by_login(params[:extensionid])
      if @showuser
        if request.post?
          if params[:explanation].nil? or params[:explanation].empty?
            flash.now[:failure] = 'An explanation for vouching for this eXtensionID is required'      
            render :template => 'people/colleagues/showuser'
          else
            if(@showuser.vouch(@currentuser))
              UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "vouched for #{@showuser.login}",:additionaldata => params[:explanation])
              UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @showuser,:description => "vouched by #{@currentuser.login}",:additionaldata => params[:explanation])
              log_user_activity(:user => @user,:activitycode => Activity::VOUCHED_FOR, :appname => 'local',:colleague => @showuser, :additionaldata => {:explanation => params[:explanation]})              
              log_user_activity(:user => @showuser,:activitycode => Activity::VOUCHED_BY, :appname => 'local',:additionaldata => {:explanation => params[:explanation]})              
              @showuser.send_welcome(true)
              flash.now[:success] = "Vouched for #{@showuser.fullname}"      
            else
              flash.now[:failure] = 'Failed to vouch for user, reported status may not be correct'      
            end
            render :template => 'people/colleagues/showuser'
          end
        else
          # show form
        end
      else
        flash.now[:warning] = 'User not found.'      
        render :template => 'people/colleagues/showuser'
      end
    else
      flash.now[:warning] = 'Missing user.'      
      render :template => 'people/colleagues/showuser'
    end        
  end
  
  def vouchlist
    @userlist = User.paginate(:all,:order => 'updated_at desc', :conditions => ["vouched = 0 AND retired = 0 AND account_status != #{User::STATUS_SIGNUP} and emailconfirmed=1"],:page => params[:page])
    @page_title = "Users pending review"
    render :template => 'people/colleagues/users'
  end
    
  def institutions
    @displayfilter = params[:displayfilter].nil? ? 'all' : params[:displayfilter]
    
    case @displayfilter
    when 'system'
      @landgrant = Institution.find_all_by_entrytype(Institution::LANDGRANT, :order => 'name') 
      @federal = Institution.find_all_by_entrytype(Institution::FEDERAL, :order => 'name') 
    when 'landgrant'
      @landgrant = Institution.find_all_by_entrytype(Institution::LANDGRANT, :order => 'name') 
    when 'federal'
      @federal = Institution.find_all_by_entrytype(Institution::FEDERAL, :order => 'name') 
    else
      @filter = 'all'
      @landgrant = Institution.find_all_by_entrytype(Institution::LANDGRANT, :order => 'name') 
      @federal = Institution.find_all_by_entrytype(Institution::FEDERAL, :order => 'name') 
    end
  end
  
  def locations
    @locations = Location.find(:all, :order => 'entrytype,name')
  end
  
  def positions
    @positions = Position.find(:all, :order => 'entrytype,name') 
  end  
  
  def socialnetworks
    @socialnetworkslist = SocialNetwork.get_networks(true)
  end
  
  def socialnetwork
    
    if(params[:id].nil?)
      return redirect_to(:action => :index)
    end
    
    if(params[:id] == 'all')
      @socialnetworklist =  SocialNetwork.paginate(:all, :include => [:user], :order => 'users.last_name', :conditions => ["users.vouched = 1 and users.retired = 0"], :page => params[:page])
      @page_title = "Social Network Identities - All Networks"
    elsif(params[:id] == 'other')
      known_list = SocialNetwork::NETWORKS.keys.sort.map{|network| "'#{network}'"}.join(",")
      @socialnetworklist =  SocialNetwork.paginate(:all, :include => [:user], :order => 'users.last_name', :conditions => ["users.vouched = 1 and users.retired = 0 and social_networks.network NOT IN (#{known_list})"], :page => params[:page])
      @page_title = "Social Network Identities - Other Networks"     
    else
      @socialnetworklist =  SocialNetwork.paginate(:all, :include => [:user], :order => 'users.last_name', :conditions => ["users.vouched = 1 and users.retired = 0 and social_networks.network = '#{params[:id]}'"], :page => params[:page])
      @page_title = "Social Network Identities - #{SocialNetwork.get_name(params[:id])}"
    end
    
    @backto = {:label => "back to Social Networks List", :url => url_for(:controller => '/people/colleagues', :action => :socialnetworks)}
    
  end

  def tagcloud
    @tagcloud = User.validusers.tag_frequency(:order => 'name')
    @all_peer_popular_tags = User.top_tags(25)
  end
  
  def tagquerybuilder
    if(request.post?)
      taglist = params[:taglist].strip
      if(taglist.blank? or taglist.length == 0)
        flash[:warning] = "Empty Interest List"
        @all_peer_popular_tags = User.top_tags(25)
        return render
      end
      
      # check commit button
      if(!params[:commit].nil? and params[:commit] == 'Match ANY')
        match = 'matchany'
      else
        match = 'matchall'
      end
      return redirect_to(:action => :tags,:taglist => taglist, :match => match)
    else
      @all_peer_popular_tags = User.top_tags(25)
    end
  end
  
  def tags
    @findoptions = {}
    
    taglist = params[:taglist].strip
    if(taglist.blank? or taglist.length == 0)
      flash[:warning] = "Empty Interest List"
      return redirect_to(:action => :tagcloud)
    end
      
    match = (!params[:match].nil? and params[:match] == 'matchany') ? 'matchany' : 'matchall'
    findtags = Tag.castlist_to_array(taglist)
    
    label = (match == 'matchall') ? "and" : "or"
    @page_title = "Colleagues interested in #{findtags.join(" #{label} ")}"
    @backto = {:label => "back to Interests List", :url => url_for(:controller => '/people/colleagues', :action => :tagcloud)}

    if(!params[:downloadreport].nil? and params[:downloadreport] == 'csv')
      reportusers = User.validusers.tagged_with_any(Tag.castlist_to_array(taglist),{:matchall => (match == 'matchall'),:order=> 'last_name,first_name'})
      csvfilename =  @page_title.tr(' ','_').gsub('\W','').downcase
      return csvuserlist(reportusers,csvfilename, @page_title)
    else
      @userlist =  User.validusers.tagged_with_any(Tag.castlist_to_array(taglist),{:matchall => (match == 'matchall'),:order=> 'last_name,first_name', :paginate => true, :page => params[:page]})
      if((@userlist.length) > 0)
        @csvreporturl = url_for(:controller => '/people/colleagues', :action => :tags, :taglist => taglist, :match => match, :downloadreport => 'csv')
      end
    end

    render :template => 'people/colleagues/users'   
  end

  def list
    @filteredparams = FilterParams.new(params)
    if(@filteredparams.dateinterval.nil?)
      @filteredparams.dateinterval = 'all'
    end
    @findoptions = @filteredparams.findoptions
    @filterstring = @filteredparams.filter_string
    
    # compatibility
    
    @page_title = "Colleagues"
    # download check    
    if(!params[:download].nil? and params[:download] == 'csv')
      @findoptions.merge!(:paginate => false)
      reportusers = User.filtered(@findoptions).ordered(@filteredparams.order).all
      csvfilename =  @page_title.tr(' ','_').gsub('\W','').downcase
      return csvuserlist(reportusers,csvfilename,@page_title)
    else
      @userlist = User.filtered(@findoptions).ordered(@filteredparams.order).paginate(:all, :page => params[:page])
      if((@userlist.length) > 0)        
        urloptions = @filteredparams.option_values_hash({:validate_wanted_parameters => false})
        ActiveRecord::Base::logger.debug "options = #{urloptions.inspect}"    
        
        urloptions.merge!({:controller => '/people/colleagues', :action => :list, :download => 'csv'})
        @csvreporturl = CGI.escapeHTML(url_for(urloptions))
      end
    end

  end

  def institution
    # backwards compatibility
    redirect_to :action => :list, :institution => params[:id]
  end
  
  def location
    # backwards compatibility
    redirect_to :action => :list, :location => params[:id]
  end

  def position
    # backwards compatibility
    redirect_to :action => :list, :position => params[:id]
  end
  
  def all
    # backwards compatibility
    redirect_to :action => :list
  end
  
  def new
    # backwards compatibility
    redirect_to :action => :list, :dateinterval => 'new'
  end
  
  def finduser
    if (!params[:searchterm].nil? and !params[:searchterm].empty?)
    
      @userlist = User.searchcolleagues({:order => 'last_name,first_name', :searchterm => params[:searchterm], :page => params[:page], :paginate => true})
      
      if @userlist.nil? || @userlist.length == 0
        flash.now[:warning] = "<p>No colleague was found that matches your search term.</p> <p>Your colleague may not yet have an eXtensionID. <a href='#{url_for(:controller => '/people/colleagues', :action => :invite)}'>Invite your colleague to get an eXtensionID</a></p>"
      else
        if @userlist.length == 1
          redirect_to :action => :showuser, :id => @userlist[0].login
        end
      end
    end
    
  end
  

  
  def showuser
    if(!params[:userid].nil?)
      findid = params[:userid]
    end
    
    if(!params[:id].nil?)
      findid = params[:id]
    end
    
    if not findid.nil?
      if(findid.to_i != 0)
        @showuser = User.find_by_id(findid)
      else
        @showuser = User.find_by_login(findid)
      end
      
      @displayprofile = true
      
      if (@showuser.nil?)
        flash.now[:failure] = 'Account not found.' 
      elsif(@showuser.retired?)  
        flash.now[:failure] = 'This person\'s account is retired.'
        @displayprofile = false if(!admin_mode?)
      elsif(@showuser.account_status == User::STATUS_SIGNUP)  
        flash.now[:failure] = 'This person has not confirmed their account'
        @displayprofile = false if(!admin_mode?)
      elsif(!@showuser.emailconfirmed?)  
        flash.now[:warning] = 'This person has not confirmed their email address'
      end
    else
      flash.now[:failure] = 'Missing eXtensionID parameter'      
    end
  end
  
  def relevantcommunities
    if(!params[:userid].nil?)
      findid = params[:userid]
    end
    
    if(!params[:id].nil?)
      findid = params[:id]
    end
    
    if not findid.nil?
      if(findid.to_i != 0)
        @showuser = User.find_by_id(findid)
      else
        @showuser = User.find_by_login(findid)
      end
      if (@showuser.nil?)
        flash[:warning] = 'User not found.' 
      elsif(@showuser.retired?)  
        flash[:warning] = 'This user account is retired.'      
      end
    else
      flash[:warning] = 'Missing user.'      
    end
    
    @relevantcommunities = @showuser.relevant_community_scores({:filtermine => false})
    respond_to do |format|
      format.html
    end
  end
  
  def xhrfindcommunity
    begin
      @showuser = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'User not found.'  
    end
    
    if(@showuser.retired?)  
      flash[:warning] = 'This user account is retired.'
    else        
      if (params[:findcommunity] and params[:findcommunity].strip != "" and params[:findcommunity].strip.length >= 3 )
        if(admin_mode?)
          @communitylist = Community.search({:order => 'name', :limit => 11, :searchterm => params[:findcommunity]})
        else
          @currentuser.search_invite_communities({:order => 'name', :limit => 11, :searchterm => params[:findcommunity]})
        end
      end
    end
    
    respond_to do |format|
      format.js
    end
    
  end  
  
  def invitetocommunity
    begin
      @showuser = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'User not found.'  
      return(redirect_to(:action => 'index'))
    end
    
    if(@showuser.retired?)  
      flash[:warning] = 'This user account is retired.'
      return(redirect_to(:action => 'index'))
    end
    
    if(params[:findcommunity] and params[:findcommunity].strip != "" )
      if ( params[:findcommunity].strip.length >= 3 )
        if(admin_mode?)
          @communitylist = Community.search({:order => 'name', :limit => 11, :searchterm => params[:findcommunity]})
        else
          @currentuser.search_invite_communities({:order => 'name', :limit => 11, :searchterm => params[:findcommunity]})
        end
      end
    elsif(admin_mode?)
      @communitylist = Community.newest(11,Community::APPROVED)
    elsif(@currentuser.communityinvitejoins.count > 0)
      @communitylist = @currentuser.communityinvitejoins
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  def xhrcommunityinvite
    # assumes @currentuser
    begin
      @showuser = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'User not found.'
      # do something?!?  
    end
    
    begin
      @community = Community.find(params[:communityid])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'Unable to find community.'
      # do something?!?  
    end

    # leadership check
    if((!@currentuser.is_community_leader?(@community) and !admin_mode?) and (!(@currentuser.communityopenjoins.include?(@community))))
      # do something?!?  
    else
      inviteasleader = (!params[:inviteasleader].nil? and params[:inviteasleader] == 'yesinviteleader')
      if (!@currentuser.is_community_leader?(@community) and !admin_mode?)
        inviteasleader = false
      end
      @community.invite_user(@showuser,inviteasleader,@currentuser)  
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def modify_community_connection
    # assumes @currentuser
    begin
      @community = Community.find(params[:communityid])
    rescue ActiveRecord::RecordNotFound  
      # need to render something
    end
    
    # leadership check
    if(!@currentuser.is_community_leader?(@community) and !admin_mode?)
      flash[:warning] = "You are not a leader for this community."
    end
      
    begin
      @showuser = User.find_by_id(params[:id])
    rescue ActiveRecord::RecordNotFound  
      flash[:error] = 'Unable to find user.'
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
  
 
  
  #----------------------------------
  # protected functions
  #----------------------------------
  protected
  
  def csvuserlist(userlist,filename,title)
      @title = title
      @userlist = userlist
      response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
      response.headers['Content-Disposition'] = 'attachment; filename='+filename+'.csv'
      render :template => 'people/common/csvuserlist', :layout => false
  end
  
end