# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


module ControllerExtensions

  def log_user_activity(opts = {})
    # creator check
    if(opts[:creator].nil?)
      @currentuser.nil? ? opts[:creator] = opts[:user] : opts[:creator] = @currentuser
    end
    Activity.log_activity(opts)
  end

  def check_openidurl_foruser(user,checkurl)
    if(user.openid_url == checkurl or user.openid_url == checkurl +'/')
      return true
    elsif(user.openid_url(true) == checkurl or user.openid_url(true) == checkurl +'/')
      return true
    else
      return false
    end
  end
  
  
  def validate_datepicker(options = {})
    flipdates = (options[:flipdates].nil? ? 'true' : options[:flipdates])
    if(params[:datefrom])
      begin
        datefrom = Date.strptime(params[:datefrom])
      rescue
        datefrom = options[:default_datefrom]
      end
    else
      datefrom = options[:default_datefrom]
    end
  
    if(params[:dateto])
      begin
        dateto = Date.strptime(params[:dateto])
      rescue
        dateto = options[:default_dateto]
      end
    else
      dateto = options[:default_dateto]
    end
    
    datefrom = options[:earliest_date] if (options[:earliest_date] and (datefrom < options[:earliest_date]))
    dateto = options[:latest_date] if (options[:latest_date] and (dateto > options[:latest_date]))
    
    if(flipdates and datefrom > dateto)
      tmp_datefrom = datefrom
      datefrom = dateto
      dateto = tmp_datefrom
    end
    
    return [datefrom,dateto]
  end  
end