# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class OpenidsessionsController < ApplicationController

  def new
    set_title('Sign in with OpenID')
    set_titletag("Sign in with OpenID - eXtension")
    @right_column = false
  end

  def create
    if !(using_open_id?)
      flash[:warning] = 'OpenID URL is required'
      return redirect_to(:action => 'new')
    end
    
    authenticate_with_open_id(params[:openid_url], :required => [ :email, :fullname ]) do |result, identity_url, registration|
      if !(result.successful?)
        return failed_login(result.message || "Sorry could not log in with identity URL: #{identity_url}")
      else
        if !(@user = User.find_by_identity_url(identity_url))
          #check to see if we have an email from the OP - if so, and they've previously "registered" with an email/pass, 
          #without an openid - then fail the login.  We'll put in an "associate my openid with a registered account" shortly
          if (!registration['email'].blank? && @user = User.find_by_email(registration['email'],:conditions => ['identity_url IS NULL']))
            gourl = "<a href='"+url_for(:controller => :session, :action => :new, :email => registration['email']) +"'>please login with your email and password</a>"
            msg = "You have already registered with us with a password, "+gourl
            return failed_login(msg)
          else
            account_creation_attributes = Hash.new
            account_creation_attributes[:identity_url] = identity_url
            account_creation_attributes[:full_name] = registration['fullname'].blank? ? 'Anonymous' : registration['fullname']
                    
            if !(@user = User.create(account_creation_attributes))
               return failed_login("Unable to process new account registration for #{identity_url}")
            else
              self.current_user = @user
              flash[:notice] = "Logged in successfully"
              redirect_to edit_user_url(:id => current_user.id)
            end
          end
        else
          self.current_user = @user
          # TODO:  we probably should update sreg attributes in case they changed at the openid provider
          successful_login
        end
      end
    end # authenticate
    rescue
      failed_login($!.to_s)
  end

  def destroy
    # probably will never get called - but repeating the session/destroy steps, yes, I know DRY, DRY, blah blah
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  def access_denied
    session[:return_to] = params[:redirect_to]
    return redirect_to(:action => 'new')
  end

  protected

    def open_id_authentication
      # Pass optional :required and :optional keys to specify what sreg fields you want.
      # Be sure to yield registration, a third argument in the #authenticate_with_open_id block.

    end

    # registration is a hash containing the valid sreg keys given above
    # use this to map them to fields of your user model
    def assign_registration_attributes(registration)
        { :email => 'email', :full_name => 'fullname' }.each do |model_attribute, registration_attribute|
          unless registration[registration_attribute].blank?
            @user.send("#{model_attribute}=", registration[registration_attribute])
          end
        end if registration
    end

    def assign_registration_attributes!(registration)
      assign_registration_attributes(registration)
      @user.save!
    end

  private

    def successful_login
      redirect_back_or_default('/')
      flash[:notice] = "Logged in successfully"
    end

    def failed_login(message)
      set_title('Log in for additional functionality.')
      set_titletag("Sign in with OpenID - eXtension")
      flash[:warning] = message
      redirect_to :action => 'new'
    end

end
