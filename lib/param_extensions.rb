# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module ParamExtensions
  
  def additionaldata_from_params(params)
    additionaldata = params
    additionaldata[:remoteaddr] = request.env["REMOTE_ADDR"]
    return additionaldata
  end
  
  def order_from_params(defaultdirection='ASC')
    # either going to be "order=columnstring direction" 
    # or it will be "orderby=columnstring&sortorder=direction"
    if(!params[:order].blank?)
      return params[:order]
    elsif(!params[:orderby].blank?)
      if(!params[:sortorder].blank?)
        return "#{params[:orderby]} #{params[:sortorder]}"
      else
        return "#{params[:orderby]} #{defaultdirection}"
      end
    else
      return nil
    end
  end
  
  #
  # ToDo:  This really needs to check for array lists
  # 
  def check_for_filters

    returnoptions = {}

    # community
    if(!params[:community].nil?)
      returnoptions[:community] = Community.find_by_id(params[:community])
    end

    # location
    if(!params[:location].nil?)
      returnoptions[:location] = Location.find_by_id(params[:location])
    end

    # county
    if(!params[:county].nil?)
      returnoptions[:county] = Location.find_by_id(params[:county])
    end
    
    # position
    if(!params[:position].nil?)
      returnoptions[:position] = Position.find_by_id(params[:position])
    end

    # institution
    if(!params[:institution].nil?)
      returnoptions[:institution] = Institution.find_by_id(params[:institution])
    end

    # person/user
    if(!params[:person].nil?)      
      # only process this when logged in
      # TODO: change when user activity is allowed to be public
      if(!@currentuser.nil?)
        if(params[:person].to_i != 0)
          returnoptions[:user] = User.find_by_id(params[:person])
        elsif(params[:person] == 'me')
          returnoptions[:user] = @currentuser
        else
          returnoptions[:user] = User.find_by_login(params[:person])
        end
      end
    end

    if(!params[:connectiontype].nil?)
      if(Communityconnection::TYPES.keys.include?(params[:connectiontype]))
        returnoptions[:connectiontype] = params[:connectiontype]
      end
    end

    if(!params[:communitytype].nil?)
      returnoptions[:communitytype] = params[:communitytype]
    end

    if(!params[:agreementstatus].nil?)
      returnoptions[:agreementstatus] = params[:agreementstatus]
    end



    # dates
    if(!params[:dateinterval].nil?)
      if(params[:dateinterval] == 'range')
        # get start and end dates and pack them up into an array
        if(!params[:datestart].nil? and !params[:dateend].nil?)
          returnoptions[:dateinterval] = [params[:datestart],params[:dateend]]
        end
      else
        returnoptions[:dateinterval] = params[:dateinterval]
      end
    end

    if(!params[:datecount].nil?)
      returnoptions[:datecount] = params[:datecount]
    end
    
    if(!params[:announcements].nil?)
      if(params[:announcements] == '1' or params[:announcements] == 'yes')
        returnoptions[:announcements] = true
      else
        returnoptions[:announcements] = false
      end
    end

    if(!params[:datefield].nil?)
      returnoptions[:datefield] = params[:datefield]
    end

    if(!params[:tz].nil?)
      returnoptions[:tz] = params[:tz]
    end

    # user activity specific
    if(!params[:activityapplication].nil?)
      returnoptions[:activityapplication] = ActivityApplication.find_by_id(params[:activityapplication])
    end

    if(!params[:appname].nil?)
      returnoptions[:appname] = params[:appname]
    end

    if(!params[:activityentrytype].nil?)
      returnoptions[:activityentrytype] = params[:activityentrytype]
    end
    
    # ip address
    if(!params[:activityaddress].nil?)
      returnoptions[:activityaddress] = params[:activityaddress]
    end
    
    if(!params[:activity].nil?)
      if(activitycodes = Activity.activity_to_codes(params[:activity]))
        returnoptions[:activity] = params[:activity]
      end
    end
    
    if(!params[:activitygroup].nil?)
      if(activitycodes = Activity.activitygroup_to_types(params[:activitygroup]))
        returnoptions[:activitygroup] = params[:activitygroup]
      end
    end

    if(!params[:ignorecommunity].nil?)
      returnoptions[:ignorecommunity] = Community.find_by_id(params[:ignorecommunity])
    end

    if(!params[:communityactivity].nil?)
      returnoptions[:communityactivity] = params[:communityactivity]
    end              
    return returnoptions
  end

  def create_filter_params(options = {})    

    returnparams = {}
    if(options.nil?)
      return {}
    end

    if(!options[:community].nil?)
      returnparams[:community] = options[:community].id
    end

    if(!options[:institution].nil?)
      returnparams[:institution] = options[:institution].id
    end

    if(!options[:location].nil?)
      returnparams[:location] = options[:location].id
    end

    if(!options[:county].nil?)
      returnparams[:county] = options[:county].id
    end
    
    if(!options[:position].nil?)
      returnparams[:position] = options[:position].id
    end

    if(!options[:user].nil?)
      returnparams[:person] = options[:user].id
    end

    if(!options[:connectiontype].nil?)
      returnparams[:connectiontype] = options[:connectiontype]
    end

    if(!options[:agreementstatus].nil?)
      returnparams[:agreementstatus] = options[:agreementstatus]
    end

    if(!options[:communitytype].nil?)
      returnparams[:communitytype] = options[:communitytype]
    end    

    # dates
    if(!options[:dateinterval].nil?)
      if(options[:dateinterval].is_a?(Array))
        # assume range
        returnparams[:dateinterval] = 'range'
        returnparams[:datestart] = options[:dateinterval][0]
        returnparams[:dateend] = options[:dateinterval][1]
      else
        returnparams[:dateinterval] = options[:dateinterval]
      end
    end

    if(!options[:datecount].nil?)
      returnparams[:datecount] = options[:datecount]
    end

    if(!options[:datefield].nil?)
      returnparams[:datefield] = options[:datefield]
    end

    if(!options[:tz].nil?)
      returnparams[:tz] = options[:tz]
    end

    # user activity specific
    if(!options[:activityapplication].nil?)
      returnparams[:activityapplication] = options[:activityapplication].id
    end
    
    if(!options[:appname].nil?)
      returnparams[:appname] = options[:appname]
    end
    
    if(!options[:activityaddress].nil?)
      returnparams[:activityaddress] = options[:activityaddress]
    end

    if(!options[:activityentrytype].nil?)
      returnparams[:activityentrytype] = options[:activityentrytype]
    end
    
    if(!options[:activity].nil?)
      returnparams[:activity] = options[:activity]
    end

    if(!options[:activitygroup].nil?)
      returnparams[:activitygroup] = options[:activitygroup]
    end

    if(!options[:ignorecommunity].nil?)
      returnparams[:ignorecommunity] = options[:ignorecommunity].id
    end

    if(!options[:communityactivity].nil?)
      returnparams[:communityactivity] = options[:communityactivity]
    end

    return returnparams

  end
end