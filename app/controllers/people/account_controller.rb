# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'uri'

class People::AccountController < ApplicationController
  include AuthCheck
  ssl_required :login,:set_password,:change_password unless (Rails.env.development? or AppConfig.configtable['app_location'] == 'localdev')
  layout 'people'
  before_filter :login_required, :except => [:login, :signup, :new_password, :set_password, :authenticate]
  before_filter :login_optional, :only => [:login]

  def review
    return redirect_to(:controller => '/people/signup', :action => :review, :status => 301)
  end

  def ajaxfindreviewer
    if (params[:findreviewer] and params[:findreviewer].strip != "" and params[:findreviewer].strip.length >= 3 )
      findstring = params[:findreviewer].gsub(/^\*/,'$')
      # test for "string1 string2" - will treat this as first last or last first - neat huh?
      words = findstring.split(%r{,\s*|\s+})
      if(words.length > 1)
        findvalues = { 
          :firstword => words[0],
          :secondword => words[1]
        }
        @reviewers = User.find(:all, :limit => 26, :order => 'last_name,first_name', :conditions => ["((first_name rlike :firstword AND last_name rlike :secondword) OR (first_name rlike :secondword AND last_name rlike :firstword)) AND users.retired = 0",findvalues])      
      else
        findvalues = {
          :findlogin => findstring,
          :findemail => findstring,
          :findfirst => findstring,
          :findlast => findstring 
        }
        @reviewers = User.find(:all, :limit => 26, :order => 'last_name,first_name', :conditions => ["(email rlike :findemail OR login rlike :findlogin OR first_name rlike :findfirst OR last_name rlike :findlast) AND users.retired = 0",findvalues])      
      end
    else
      @reviewers = []
    end

    render(:update) do |page|
        page.replace_html  :users_table, :partial => 'review_users_table'
    end

  end

  def confirmemail
    @sendmode = false
    @tokenexpired = false
    @tokeninvalid = false

    if (@currentuser.emailconfirmed? and params[:force].nil?)
      flash[:warning] = "Your email address is already confirmed."
      return redirect_to(people_welcome_url) 
    end

    if params[:token] != nil
      if (params[:token] == 'send')
        @sendmode = true
        @currentuser.send_email_confirmation
      else
        @token = UserToken.find_by_token(params[:token])    
        if ((@token.nil?) or (@token.user != @currentuser) or @token.tokentype != UserToken::EMAIL)
          @tokeninvalid = true
          flash.now[:failure] = "Invalid token."
        elsif @token.token_expired?
          @tokenexpired = true
          flash.now[:failure] = "Token expired."          
        else
          now = Time.now.utc
          if(!@currentuser.vouched? and !@currentuser.check_email_review?) # self-vouch check
            @currentuser.vouched = true 
            @currentuser.vouched_by = @currentuser.id
            @currentuser.vouched_at = now
          end
          @currentuser.emailconfirmed = true
          @currentuser.email_event_at = now
          @currentuser.save
          @currentuser.checklistemails
          UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "email confirmed")              
          flash[:success] = "Email address confirmed."
          @token.destroy
          allemailtokens = @currentuser.user_tokens.find(:all,:conditions => ["user_tokens.tokentype = ?",UserToken::EMAIL])
          @currentuser.user_tokens.delete(allemailtokens) if allemailtokens                  
          if (@currentuser.vouched?)
            Notification.create(:notifytype => Notification::WELCOME, :account => @currentuser, :send_on_create => true)
            return redirect_to(people_welcome_url)
          else
            Notification.create(:notifytype => Notification::ACCOUNT_REVIEW, :account => @currentuser, :send_on_create => true)        
            return redirect_to(:controller => 'account', :action => 'review')
          end  
        end
      end
    end # nil token - will prompt
  end

  def contributor_agreement
      save = false    
      if(@currentuser.contributor_agreement.nil?) 
        if(!params[:agreement_agree].nil?)
             @currentuser.contributor_agreement = 1
             label = "accepted"
             save = true
        elsif(!params[:agreement_noagree].nil?)
             @currentuser.contributor_agreement = 0
             label = "did not accept"
             save = true
        else
          # nothing
        end

        if(save)
          @currentuser.contributor_agreement_at = Time.now.utc
          @currentuser.save
          UserEvent.log_event(:etype => UserEvent::AGREEMENT, :user => @currentuser,:description => "#{label} contributor agreement")      
          flash[:success] = "Thank you for your response"
          redirect_to :action => :contributor_agreement
        end
      end
  end
            
  def login
    @openidmeta = openidmeta(@openiduser)
    if request.post?
      result = authuser(params[:email],params[:password])
      if(AUTH_SUCCESS != result[:code] and result[:localfail])
        if(result[:localfail])
          flash.now[:failure]  = explainauthresult(result[:code])
          if(AUTH_PASSWORD_EXPIRED == result[:code])
            result[:user].send_resetpass_confirmation
          end
          UserEvent.log_event(:etype => UserEvent::LOGIN_LOCAL_FAILED,:user => result[:user], :description => 'login failed ('+authlogmsg(result[:code])+')')                  
        end
      else
        @currentuser = result[:user]
        @currentuser.update_attribute(:last_login_at,Time.now.utc)
        session[:userid] = @currentuser.id
        session[:account_id] = @currentuser.id
        flash.now[:success] = "Login successful."
        UserEvent.log_event(:etype => UserEvent::LOGIN_LOCAL_SUCCESS,:user => @currentuser,:description => 'login')        
        log_user_activity(:user => @currentuser,:activitytype => Activity::LOGIN, :activitycode => Activity::LOGIN_PASSWORD, :appname => 'local')
        redirect_back_or_default(people_welcome_url)
      end
    else
      if(!@currentuser.nil?)
        redirect_to(people_welcome_url)
      end
    end
  end
        
  def signup
    return redirect_to(:controller => '/people/signup', :action => :new, :invite => params[:invite], :status => 301)
  end
  
  def change_password
    if request.post?
      @currentuser = User.find_by_id(session[:userid])
      if not @currentuser.checkpass(params[:old_password])
        flash.now[:failure] = "Password incorrect."
      else
        # hmmmmmmmmm
        if @currentuser.update_attributes(params[:user])
          UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "changed password")                      
          flash[:success] = "Password changed."
          redirect_to(:controller => 'profile', :action => 'me')
        else
          UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "change password failed")                                
          flash.now[:failure] = "Unable to change password."
        end
      end
      
    end
  end

  def logout
    @currentuser = nil
    session[:userid] = nil
    session[:adminmode] = 0
    session[:last_opierequest] = nil
    # TODO:  I have no idea what these are - they very much need to be more descriptive
    session[:via_conduita] = nil; session[:via_conduitb] = nil
    session[:first_set]= nil; session[:sec_set] = nil
    session[:left_set] = nil; session[:right_set] = nil
    session[:set1] = nil; session[:set2] = nil
    session[:aae_search] = nil
  end
    
  def new_password
    # just in case we got here from an openid login
    session[:last_opierequest] = nil
    
    @sentmail = false
    if request.post?
      @requestuser = User.find_by_login(params[:login_or_email])
      if nil == @requestuser
        @requestuser = User.find_by_email(params[:login_or_email])
      end
      
      if nil == @requestuser
         flash.now[:warning] = 'User not found.'
      elsif(AppConfig.configtable['reserved_uids'].include?(@requestuser.id))
         flash.now[:warning] = 'Unable to reset the password for this user.'
      else
         @requestuser.send_resetpass_confirmation
         @sentmail = true
         flash.now[:success] = 'Confirmation email sent!'
      end
    end
  end
  
  def set_password
    @notoken = true
    @tokenexpired = false
    if params[:token] != nil
      @token = UserToken.find_by_token_and_tokentype(params[:token],UserToken::RESETPASS)
      if @token.nil?
        flash.now[:warning] = 'Token not found.'
      elsif @token.token_expired?
        @notoken = false
        @tokenexpired = true
      else
        flash.now[:success] = 'Token validated.'
        @requestuser = @token.user      
        @notoken = false
        if request.post?
          if(params[:user])
            result = @requestuser.set_new_password(@token,params[:user][:password],params[:user][:password_confirmation])
            if(result)
              flash[:success] = "New password set. Please login with your new password."
              session[:userid] = nil
              redirect_to :action => 'login'
            else
              UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @requestuser,:description => "set new password failed")                                              
              flash.now[:failure] = "Unable to set new password."
            end
          else
            # show the set new password form
            # logging here because otherwise it would log twice   
            UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @requestuser,:description => "confirmed new password request")                                              
          end          
        end
      end
    else
      # show token confirmation form
    end
  end

end
