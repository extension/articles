# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class People::SignupController < ApplicationController
  include AuthCheck 
  layout 'people'
  before_filter :login_required, :only => [:confirm, :reconfirm, :confirmationsent, :review]

  def readme
    # just in case we got here from an openid login
    session[:last_opierequest] = nil
     
    if(!params[:invite].nil?)
      @invitation = Invitation.find_by_token(params[:invite])
    end
  end
  
  def new
    if(!request.post?)
      return redirect_to(:action => 'readme', :invite => params[:invite])
    end
    
    # just in case we got here from an openid login
    session[:last_opierequest] = nil
    
    if(!params[:invite].nil?)
      @invitation = Invitation.find_by_token(params[:invite])
    end
    
    if params[:user]
      @user = User.new(params[:community])
    else
      @user = User.new
    end
    
    @locations = Location.displaylist
    if(!(@user.location.nil?))  
      @countylist = @user.location.counties
    end
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def create
    if(!params[:invite].nil?)
      @invitation = Invitation.find_by_token(params[:invite])
    end
    
    @user = User.new(params[:user])
    
    # institution
    if(!params[:institution].nil? and !params[:institution][:name].nil?)
      @user.institution = Institution.find_existing_or_create_new_user_institution(params[:institution][:name],@user.login)
    end
    
    # STATUS_SIGNUP
    @user.account_status = User::STATUS_SIGNUP

    begin
      didsave = @user.save
    rescue ActiveRecord::StatementInvalid => e
      if(!(e.to_s =~ /duplicate/i))
        raise
      end
    end
    
    if(!didsave)
      if(!@user.errors.on(:email).nil? and @user.errors.on(:email) == 'has already been taken')
        failuremsg = "Your email address has already been registered with us.  If you've forgotten your password for that account, please <a href='#{url_for(:controller => 'people/account', :action => :new_password)}'>request a new password</a>"
        flash.now[:failure] = failuremsg
      elsif(!@user.errors.empty?)
        failuremsg = "<h3>There were errors that prevented signup</h3>"
        failuremsg += "<ul>"
        @user.errors.each { |value,msg|
          if (value == 'login')
            failuremsg += "<li>That eXtensionID #{msg}</li>"
          else
            failuremsg += "<li>#{value} - #{msg}</li>"
          end
        }
        failuremsg += "</ul>"          
        flash.now[:failurelist] = failuremsg
      end
      @locations = Location.displaylist
      if(!(@user.location.nil?))  
        @countylist = @user.location.counties
      end
      render :action => "new"
    else        
      # automatically log them in
      @currentuser = User.find_by_id(@user.id)
      session[:userid] = @currentuser.id
      if(@invitation)
        signupdata = {:invitation => @invitation}
      else
        signupdata = nil
      end
      UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "initialsignup")        
      @currentuser.send_signup_confirmation(signupdata)
      return redirect_to(:action => :confirmationsent)
    end
  end
  
  
  def confirm
    if(@currentuser.account_status != User::STATUS_SIGNUP)
      return redirect_to(people_welcome_url) 
    end
    
    if(params[:token].nil?)
      return render(:template => 'people/signup/confirm')
    end
    
    if (params[:token] == 'send')
      flash[:success] = "Resent Signup Confirmation"          
      @currentuser.resend_signup_confirmation
      return redirect_to(:controller => 'signup', :action => 'confirmationsent')      
    end
    
    @token = UserToken.find_by_token(params[:token])
    if ((@token.nil?) or (@token.user != @currentuser) or @token.tokentype != UserToken::SIGNUP)
      flash[:failure] = "Invalid token."
      return redirect_to(:controller => 'signup', :action => 'reconfirm', :reason => 'invalidtoken')
    elsif(@token.token_expired?)
      flash[:failure] = "Token expired."          
      return redirect_to(:controller => 'signup', :action => 'reconfirm', :reason => 'expiredtoken')
    else
      @currentuser.confirm_signup(@token)

      if (@currentuser.vouched?)            
        @currentuser.send_welcome
        return redirect_to(people_welcome_url)
      else
        @currentuser.send_review_request
        return redirect_to(:controller => 'signup', :action => 'review')
      end
    end    
  end
  
  def confirmationsent
  end
  
  def reconfirm
    @reason = params[:reason]
  end
  
  def postsignup
  end
  
  def review
  end
  
  
  def auto_complete_for_institution_name
    if(!params[:institution].nil? and !params[:institution][:name].nil?)
      institutionlist = Institution.searchmatching({:order => 'entrytype ASC,name', :searchterm => params[:institution][:name],:limit => 11}) 
    end
    render(:partial => 'people/profile/institutionlist', :locals => { :institutionlist => institutionlist })
  end
  
  def fetch_signup_county_and_institution
    @globalinstitutions = Institution.get_federal_nolocation
    if(!params[:location].nil? and params[:location] != "")
      selected_location = Location.find(:first, :conditions => ["id = ?", params[:location]])	  
      @counties = selected_location.counties
      @locationinstitutions = get_location_institutions(selected_location)
    end

    render(:update) do |page|
        page.replace_html  :location, :partial => 'signup_county_and_institution'
    end
  end
  
end
