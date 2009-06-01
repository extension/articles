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
  wantsparameter :activity, :string #TODO sanity check
  wantsparameter :activitygroup, :string # TODO sanity check
  
  wantsparameter :ignorecommunity, :community
  wantsparameter :communityactivity, :string

  # gdata params
  # published-min, published-max
  # updated-min, updated-max
  # alt
  # author
  # category
  # q
  # prettyprint
  # max-results
  
  
  
  

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

  # 

  #   
  #   
  #   if(!params[:activity].nil?)
  #     if(activitycodes = Activity.activity_to_codes(params[:activity]))
  #       returnoptions[:activity] = params[:activity]
  #     end
  #   end
  #   
  #   if(!params[:activitygroup].nil?)
  #     if(activitycodes = Activity.activitygroup_to_types(params[:activitygroup]))
  #       returnoptions[:activitygroup] = params[:activitygroup]
  #     end
  #   end
  # 

end