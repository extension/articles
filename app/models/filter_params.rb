# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class FilterParams < ParamExtensions::ParamsFilter
  wantsparameter :community, :community
  wantsparameter :location, :location
  wantsparameter :county, :county
  wantsparameter :position, :position
  wantsparameter :institution, :institution
  wantsparameter :person, :user
  wantsparameter :connectiontype, :string
  wantsparameter :communitytype, :string
  wantsparameter :agreementstatus, :boolean
  wantsparameter :announcements, :boolean

  wantsparameter :order, :string
  wantsparameter :orderby, :string
  wantsparameter :sortorder, :string

  wantsparameter :dateinterval, :string
  wantsparameter :datefield, :string
  wantsparameter :tz, :string
  
  wantsparameter :appname, :string
  wantsparameter :activityapplication, :activity_application
  wantsparameter :activityentrytype, :string
  wantsparameter :activityaddress, :string
  wantsparameter :activity
  wantsparameter :activitygroup
  
  wantsparameter :ignorecommunity, :community
  wantsparameter :communityactivity, :string

  # gdata params
  wantsparameter :author, :user
  wantsparameter 'published-min', :datetime
  wantsparameter 'published-max', :datetime
  wantsparameter 'updated-min', :datetime
  wantsparameter 'updated-max', :datetime
  
  # TODO:
  # alt
  # category
  # q
  # prettyprint
  # max-results
  
  
  
  # -----------------------------------
  # instance methods
  # -----------------------------------
  
  # sanity checks provided activity string
  def activity
    if(activitycodes = Activity.activity_to_codes(read_parameter(:activity)))
      return read_parameter(:activity)
    else
      return nil
    end
  end
  
  # sanity checks provided activitygroup string
  def activitygroup
    if(activitycodes = Activity.activitygroup_to_types(read_parameter(:activitygroup)))
      return read_parameter(:activitygroup)
    else
      return nil
    end
  end
    

  #   # dates
  #   if(!params[:dateinterval].nil?)
  #     if(params[:dateinterval] == 'range')
  #       # get start and end dates and pack them up into an array
  #       if(!params[:datestart].nil? and !params[:dateend].nil?)
  #         returnoptions[:dateinterval] = [params[:datestart],params[:dateend]]
  #       end
  #     else
  #       returnoptions[:dateinterval] = params[:dateinterval]
  #     end
  #   end
  # 
  #   
  # 

end