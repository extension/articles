# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class People::ProfileController < ApplicationController
  layout 'people'
  before_filter :login_required, :except => [:xhr_countylist]
  protect_from_forgery :except => :auto_complete_for_institution_name
  
  def me
  end
  
  def account
  end
  
  def allevents
    @events = UserEvent.paginate(:all, :order => 'created_at desc', :conditions => ['login = :login or login = :email', { :login => @currentuser.login, :email => @currentuser.email }], :page => params[:page])
  end
  
  def recent
    @activitylist = @currentuser.activities.paginate(:all, :order => 'created_at DESC', :page => params[:page])
  end
  
  def openid
  end
  
  def change_privacy_setting
    @privacysetting = PrivacySetting.find_by_id(params[:id])
    if (@privacysetting.user == @currentuser)
      if(!params[:show_publicly].nil? and params[:show_publicly] == 'yes')
        @privacysetting.update_attribute(:is_public, true)
      else
        @privacysetting.update_attribute(:is_public, false)
      end
    end
         
    respond_to do |format|
      format.js
    end
  end
  
  def change_social_network_privacy
    @socialnetwork = SocialNetwork.find_by_id(params[:id])
    if (@socialnetwork.user == @currentuser)
      if(!params[:show_publicly].nil? and params[:show_publicly] == 'yes')
        @socialnetwork.update_attribute(:is_public, true)
      else
        @socialnetwork.update_attribute(:is_public, false)
      end
    end
         
    respond_to do |format|
      format.js
    end
  end
  
  def publicsettings  
    # build the settings list - this is a little weird because we might not have all of these settings, so we are going to query for all of them
    @publicsettings = []
    PrivacySetting::KNOWN_ITEMS.each do |item|
      @publicsettings << PrivacySetting.find_or_create_by_user_and_item(@currentuser,item)
    end
    
      
    
  end
  
  def socialnetworks
    if request.post?      
      @currentuser.modify_social_networks(params[:socialnetworks])
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "social networks updated",:additionaldata => additionaldata_from_params(params))
      log_user_activity(:user => @currentuser,:activitycode => Activity::UPDATE_PROFILE, :appname => 'local')                    
      flash[:success] = 'Networks updated.'
      redirect_to(:controller => 'profile', :action => 'me')
    else
      @socialnetworkslist = SocialNetwork.get_edit_networks
    end
  end
  
  
  def otheremails
    if request.post?      
      @currentuser.modify_user_emails(params[:useremails])
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "other emails updated",:additionaldata => additionaldata_from_params(params))
      log_user_activity(:user => @currentuser,:activitycode => Activity::UPDATE_PROFILE, :appname => 'local')                    
      flash[:success] = 'Emails updated.'
      redirect_to(:controller => 'profile', :action => 'me')
    else
      #show form
    end
  end
  
  def removeopenidsite
    if not params[:id].nil?
      @removesite = @currentuser.opie_approvals.find(params[:id])
      if @removesite
        if request.post?
          if(@currentuser.opie_approvals.delete(@removesite))
            flash[:success] = 'Removed trusted OpenID site.'
            UserEvent.log_event(:etype => UserEvent::OPENID,:user => @currentuser,:description => "removed trusted openid site",:additionaldata => @removesite)                                                                            
          else
            flash[:failure] = 'Failed to remove trusted OpenID site.'            
          end
          redirect_to(:action => 'openid')
        end
      else
        # show form
      end
    else
      flash[:warning] = 'Missing OpenID site.'      
      redirect_to(:action => 'openid')
    end
  end
  
  def edit
    @user = @currentuser
    if(!request.post?)
      @locations = Location.displaylist
      if(!(@currentuser.location.nil?))  
        @countylist = @currentuser.location.counties
      end
    else
      # institution
      if(!params[:institution].nil?)
        if(!params[:institution][:name].blank?)
          @currentuser.institution = Institution.find_existing_or_create_new_user_institution(params[:institution][:name],@currentuser.login)
        else
          @currentuser.institution = nil
        end
      end
      @currentuser.attributes=(params[:user])
            
      # emailchange?
      emailchanged = @currentuser.email_changed?
      
      # announce change?
      announcechange = @currentuser.announcements_changed?
      
      if @currentuser.save
        UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "profile updated",:additionaldata => additionaldata_from_params(params))
        log_user_activity(:user => @currentuser,:activitycode => Activity::UPDATE_PROFILE, :appname => 'local')   
        if announcechange
          @currentuser.reload
          @currentuser.checkannouncelists
        end           
        if emailchanged
          UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "email address change")                                                                            
          if(@currentuser.account_status == User::STATUS_INVALIDEMAIL_FROM_SIGNUP)
            @currentuser.resend_signup_confirmation            
            return redirect_to(:controller => 'signup', :action => 'confirmationsent')      
          else
            @currentuser.send_email_confirmation
            return render(:action => 'emailchange')
          end
        else
          flash[:success] = 'User profile updated.'
          return redirect_to(:controller => 'profile', :action => 'me')
        end
      else
        @locations = Location.displaylist
        if(!(@currentuser.location.nil?))  
          @countylist = @currentuser.location.counties
        end
      end      
    end
  end
  
  def communitymemberships
    # convenience method to do redirection to new communities controller
    return redirect_to(:controller => '/people/communities', :action => :mine)
  end
  
  def auto_complete_for_institution_name
    institutionlist = Institution.searchmatching({:order => 'entrytype,name', :searchterm => params[:institution][:name],:limit => 11}) 
    render(:partial => 'institutionlist', :locals => { :institutionlist => institutionlist })
  end
  
  def editinstitution
    @user = @currentuser
    render(:update) do |page|
      page.replace_html "institution", :partial => 'edit_institution'
    end
  end
  
  def editinstitution
    @user = @currentuser
    render(:update) do |page|
      page.replace_html "institution", :partial => 'edit_institution'
    end
  end
  
  def canceleditinstitution
    @user = @currentuser
    render(:update) do |page|
      page.replace_html("institution", :partial => 'profile_field_institution', :locals => {:user => @user})
    end		
  end
  
  def xhr_countylist
    @user = @currentuser
    if(!params[:location].nil? and params[:location] != "")
      selected_location = Location.find(:first, :conditions => ["id = ?", params[:location]])	  
      @countylist = selected_location.counties
    end

    render(:update) do |page|
        page.replace_html  :county, :partial => 'county', :locals => {:countylist => @countylist}
    end    
  end
  
  def xhr_socialnetworkurl
    fieldid = (!params[:fieldid].nil?) ? params[:fieldid] : 'blah' 
    network = (!params[:network].nil?) ? params[:network] : 'other' 
    accountid = (!params[:accountid].nil?) ? params[:accountid] : ''
    newrecord = (!params[:newrecord].nil? and params[:newrecord] == 'yes')
    label =  newrecord ? 'new' : 'existing' 
  
    if(network != "" and accountid != "")
      accounturl = SocialNetwork.get_network_url(network,accountid)	  
    else
      accounturl = ''
    end
  
    render(:update) do |page|
        page.replace_html  "socialnetworkurl_#{fieldid}", :partial => 'socialnetworkurl', :locals => {:newrecord => newrecord, :network => network, :label => label, :fieldid => fieldid, :accounturl => accounturl}
    end   
  end
  
  def xhr_newsocialnetwork
    networkname = params[:networkname].nil? ? "other" : params[:networkname] 
    newnetwork = SocialNetwork.new(:network => networkname)
    render(:update) do |page| 
      page.insert_html :top, :socialnetworks, :partial => 'social_network', :locals => {:networkname => networkname, :social_network => newnetwork}
      page.visual_effect :highlight, "socialnetwork_item_#{newnetwork.object_id}"
    end
  end
  
  def tagedit
    if request.post?
      @currentuser.tag_myself_with(params[:tag_list].strip)
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "interests updated",:additionaldata => additionaldata_from_params(params))
      log_user_activity(:user => @currentuser,:activitycode => Activity::UPDATE_PROFILE, :appname => 'local')                    
      flash[:success] = 'Interests updated.'
      redirect_to(:controller => 'profile', :action => 'me')
    else
      #show form
      @position_peer_popular_tags = @currentuser.peer_top_tags("position",10)
      @all_peer_popular_tags = User.top_tags(10)
    end
  end
  
  def communities
    
  end
  
  def lists
    
  end
    
  def relevantcommunities
    @relevantcommunities = @currentuser.relevant_community_scores({:filtermine => false})
    @page_title = "Relevant Communities"
    respond_to do |format|
      format.html
    end
  end
  
 end