# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module Aae::ReportsHelper
 
  
  def is_marked(type, via_conduit)
    #if not here before
    # set both checkboxes on
    #else
    # set on only what is on now
      if !session[via_conduit]
        session[via_conduit] = [true, "wait"]
        return true
      else
        if session[via_conduit][1]=="wait"
          session[via_conduit][1]= true
          return true
        else 
            if (type)=="public"
              i = 0
            else
              i = 1
           end
           return session[via_conduit][i] 
           
        end
      end

  end
  
  def get_aae_symbols(user, question_wranglers, auto_routers)
    ret_string = ''
    
    ret_string << ' *' if auto_routers.include?(user.id)
    ret_string << ' +' if question_wranglers.include?(user.id)
    return ret_string
  end
 
  def avg_display(avg)
    if (avg && (avg > 24))   #24 hours in day, assumes hourly input
      return ("%.2f" % (avg/24.0)).to_s
    else
      if avg && (avg/24.0 > 0)
        return ("%.2f" % avg).to_s
      else
        return "No Data"
      end
    end
  end
  
  def avg_display_units(avg)
    if (avg && (avg > 24))   #24 hours in day, assumes hourly input
      return "Days"
    else
      if avg && (avg/24.0 > 0)
       return "Hours"
      else
        return ""
      end
    end
  end
        
end
