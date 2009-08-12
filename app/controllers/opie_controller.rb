# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require "openid"
require 'openid_ar_store'
require 'openid/consumer/discovery'
require 'openid/extensions/sreg'

# extend the data fields for the SReg Request/Response

module OpenID
  module SReg
    DATA_FIELDS = {
      'fullname'=>'Full Name',
      'nickname'=>'Nickname',
      'dob'=>'Date of Birth',
      'email'=>'E-mail Address',
      'gender'=>'Gender',
      'postcode'=>'Postal Code',
      'country'=>'Country',
      'language'=>'Language',
      'timezone'=>'Time Zone',
      'extensionid'=>'eXtension ID',
    }
  end
end

class OpieController < ApplicationController
  layout nil
  include OpenID::Server
  include ApplicationHelper
  

  skip_before_filter :verify_authenticity_token
  before_filter(:login_required, :only => [:decision])
  before_filter(:check_purgatory, :only => [:decision])
  
  def delegate
    @openiduser = User.find_by_login(params[:extensionid])
    @openidmeta = openidmeta(@openiduser)
    if(!@openiduser.nil?)
      @publicattributes = @openiduser.public_attributes
    end
    render(:layout => 'peopledelegate')
  end
  
  def index
    # first thing, if we came back here from a login - get the request out of the session
    if(!params[:returnfrom].nil? and params[:returnfrom] == 'login')
      opierequest = session[:last_opierequest]
      if(opierequest.nil?)
        flash[:failure] = "An error occurred during your OpenID login.  Please return to the site you were using and try again."
        return redirect_to(people_welcome_url)
      else
        # clear it out of the session
        session[:last_opierequest] = nil
      end
    else    
      begin
        opierequest = server.decode_request(params)
      rescue ProtocolError => e
        # invalid openid request, so just display a page with an error message
        render(:text => e.to_s)
        return
      end
    end
      
    # no openid.mode was given
    unless opierequest
      render(:text => "This is an OpenID server endpoint.")
      return
    end
    # 
    
    proto = request.ssl? ? 'https://' : 'http://'
    server_url = url_for(:action => 'index', :protocol => proto)
    
    if opierequest.kind_of?(CheckIDRequest)
      
      if self.is_authorized(opierequest.id_select,opierequest.identity, opierequest.trust_root)
        if(opierequest.id_select)
          if(opierequest.message.is_openid1)
            response = opierequest.answer(true,server_url,@currentuser.openid_url(true))            
          else
            response = opierequest.answer(true,nil,@currentuser.openid_url,@currentuser.openid_url(true))
          end
        else
          response = opierequest.answer(true)          
        end
        # add the sreg response if requested
        self.add_sreg(opierequest, response)
        UserEvent.log_event(:etype => UserEvent::LOGIN_OPENID_SUCCESS,:user => @currentuser,:description => 'openid login',:additionaldata => opierequest,:appname => opierequest.trust_root)                  
        log_user_activity(:user => @currentuser,:activitytype => Activity::LOGIN, :activitycode => Activity::LOGIN_OPENID,:trustroot => opierequest.trust_root)                                     
      elsif opierequest.immediate
        response = opierequest.answer(false, server_url)
      else
        if (self.checklogin(opierequest.id_select,opierequest.identity,opierequest.trust_root))
          if(!check_purgatory)
            return
          end
          session[:last_opierequest] = opierequest
          @opierequest = opierequest
          flash[:notice] = "Do you trust this site with your identity?"
          proto = request.ssl? ? 'https://' : 'http://'
          @desicionurl = url_for(:controller => 'opie', :action => 'decision', :protocol => proto)
          sregrequest = OpenID::SReg::Request.from_openid_request(opierequest)
          if(!sregrequest.nil?)
            askedfields = (sregrequest.required+sregrequest.optional).uniq
            @willprovide = []
            askedfields.each do |field|
              case field
                when 'nickname'
                  @willprovide << "Nickname: #{@currentuser.first_name}"
                when 'email'
                  @willprovide << "Email: #{@currentuser.email}"
                when 'fullname'
                  @willprovide << "Fullname: #{@currentuser.first_name} #{@currentuser.last_name}"
                when 'extensionid'
                  @willprovide << "eXtensionID: #{@currentuser.login}"                
                else
                  # nada
              end # case
            end # askedfields
          end
          render(:template => 'opie/decide', :layout => 'people')
        else
          @currentuser = nil
          session[:userid] = nil
          session[:last_opierequest] = opierequest
          session[:return_to] = url_for(:controller=>"opie", :action =>"index", :returnfrom => 'login')
          return(redirect_to login_url)
        end
        return
      end

    else
      response = server.handle_request(opierequest)
    end
  
    self.render_response(response)
  end

  def user
    @openiduser = User.find_by_login(params[:extensionid])
    # Yadis content-negotiation: we want to return the xrds if asked for.
    accept = request.env['HTTP_ACCEPT']
    
    # This is not technically correct, and should eventually be updated
    # to do real Accept header parsing and logic.  Though I expect it will work
    # 99% of the time.
    if (accept and accept.include?('application/xrds+xml') and !@openiduser.nil?)
      return user_xrds
    end

    # content negotiation failed, so just render the user page 
    if(@openiduser.nil?)
      flash.now[:failure] = 'No user by that name here.'
    else
      @openidmeta = openidmeta(@openiduser)
      @publicattributes = @openiduser.public_attributes
    end
    @right_column = false
    render(:layout => 'publicdelegate')
  end

  def idp_xrds
    types = [OpenID::OPENID_IDP_2_0_TYPE]
    types_string = ''
    types.each do |type|
      types_string += "<Type>#{type}</Type>\n"
    end

    yadis = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="1">
      #{types_string}
      <URI>#{url_for(:controller => 'opie',:protocol => request.protocol)}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
EOS

    response.headers['content-type'] = 'application/xrds+xml'
    render(:text => yadis)
  end 

  def user_xrds
    @openiduser = User.find_by_login(params[:extensionid])
    if(@openiduser.nil?)
      redirect_to(:action => 'user')
    end
    
    types = [OpenID::OPENID_2_0_TYPE, OpenID::OPENID_1_0_TYPE,OpenID::SREG_URI]
    types_string = ''
    types.each do |type|
      types_string += "<Type>#{type}</Type>\n"
    end

    yadis = '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
    yadis += '<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">'+"\n"
    yadis += "<XRD>\n"
    yadis += '<Service priority="0">' + "\n"
    yadis += "#{types_string}\n"
    yadis += "<URI>#{url_for(:controller => 'opie',:protocol => request.protocol)}</URI>\n"
    yadis += "<LocalID>#{@openiduser.openid_url}</LocalID>\n"
    yadis += "</Service>\n"
    yadis += "</XRD>\n"
    # if(@openiduser.openid_url != @openiduser.openid_url(true))
    #   yadis += "<XRD>\n"
    #   yadis += '<Service priority="10">' + "\n"
    #   yadis += "#{types_string}\n"
    #   yadis += "<URI>#{url_for(:controller => 'opie',:protocol => request.protocol)}</URI>\n"
    #   yadis += "<LocalID>#{@openiduser.openid_url(true)}</LocalID>\n"
    #   yadis += "</Service>\n"
    #   yadis += "</XRD>\n"
    # end
    yadis += "</xrds:XRDS>\n"
    response.headers['content-type'] = 'application/xrds+xml'
    render(:text => yadis)
  end

  def decision
    opierequest = session[:last_opierequest]
    if(opierequest.nil?)
      # try to redirect back - because something really weird happened with the session
      if(!request.env["HTTP_REFERER"].nil?)
        return redirect_to(request.env["HTTP_REFERER"])
      else
        # intentionally crash it
        flash[:failure] = "An error occurred during your OpenID login.  Please return to the site you were using and try again."
        return redirect_to(people_welcome_url)
      end
    end

    if params[:Allow].nil?
      session[:last_opierequest] = nil
      return redirect_to(opierequest.cancel_url)
    else
      if(!self.approved(opierequest.trust_root))
        @currentuser.opie_approvals.create(:trust_root => opierequest.trust_root)
      end
      # proto = request.ssl? ? 'https://' : 'http://'
      # server_url = url_for(:action => 'index', :protocol => proto)
      if(opierequest.id_select)
        response = opierequest.answer(true,nil,@currentuser.openid_url,@currentuser.openid_url(true))
      else
        response = opierequest.answer(true)          
      end
      self.add_sreg(opierequest, response)
      UserEvent.log_event(:etype => UserEvent::LOGIN_OPENID_SUCCESS,:user => @currentuser,:description => 'openid login',:additionaldata => opierequest,:appname => opierequest.trust_root)                  
      log_user_activity(:user => @currentuser,:activitytype => Activity::LOGIN, :activitycode => Activity::LOGIN_OPENID,:trustroot => opierequest.trust_root)                                     
      session[:last_opierequest] = nil
      return self.render_response(response)
    end
  end

  protected


  def checklogin(is_idselect,identity,trust_root)
    if session[:userid]
      checkuser = User.find_by_id(session[:userid])
      if not checkuser      
        return false
      elsif(is_idselect)
        @currentuser = checkuser
        return true
      else
        if(check_openidurl_foruser(checkuser,identity))
          @currentuser = checkuser
          return true
        else
          flash[:failure] = "The OpenID you used doesn't match the OpenID for your account.  Please use your back button and enter your OpenID: #{checkuser.openid_url(true)}"
          return false
        end
      end
    else
      return false
    end
  end

  def server
    if @server.nil?
      endpoint = url_for(:action => 'index', :only_path => false)
      store = ActiveRecordStore.new
      @server = Server.new(store,endpoint)
    end
    return @server
  end

  def approved(trust_root)
    if(OpieApproval.find(:first, :conditions => ['user_id = ? and trust_root = ?',@currentuser.id,trust_root]))
      return true
    else
      return false
    end
  end

  def is_authorized(is_idselect,identity,trust_root)
    if(self.checklogin(is_idselect,identity,trust_root))
      return self.approved(trust_root)
    else
      return false
    end
  end

  def add_sreg(opierequest, response)

    sregrequest = OpenID::SReg::Request.from_openid_request(opierequest)
    return if sregrequest.nil?
        
    # currently we'll hand out nickname, full name, email, and extensionid    
    sreg_response_data = {}
    askedfields = (sregrequest.required+sregrequest.optional).uniq
    askedfields.each do |field|
      case field
        when 'nickname'
          sreg_response_data['nickname'] = @currentuser.first_name
        when 'email'
          sreg_response_data['email'] = @currentuser.email
        when 'fullname'
          sreg_response_data['fullname'] = @currentuser.fullname
        when 'extensionid'
          sreg_response_data['extensionid'] = @currentuser.login        
        else
          logger.debug("OpenID Consumer asked for field: #{field} - we don't know how to answer that.")
      end
    end
    
    sregresponse = OpenID::SReg::Response.extract_response(sregrequest, sreg_response_data)
    response.add_extension(sregresponse)
  end

  def render_response(openidresponse)    
    if openidresponse.needs_signing
      signed_response = server.signatory.sign(openidresponse)
    end
    web_response = server.encode_response(openidresponse)

    case web_response.code
    when HTTP_OK
      render :text => web_response.body, :status => 200

    when HTTP_REDIRECT
      redirect_to web_response.headers['location']

    else
      render :text => web_response.body, :status => 400
    end
  end
  
  protected
  

  
  
end
