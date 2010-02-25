# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Api::DataController < ApplicationController

  def communities
    filteredparams = ParamsFilter.new([:apikey,:communitytype],params)
    apikey = (filteredparams.apikey.nil? ? ApiKey.systemkey : filteredparams.apikey)
    # TODO: consider doing this automatically in application_controller as a before_filter
    ApiKeyEvent.log_event("#{controller_path}/#{action_name}",apikey)
  
    returnhash = {:success => true, :communities => {}, :version => 1}
    case filteredparams.communitytype
    when 'all'
      communitylist = Community.all(:order => 'name')      
    when 'approved'
      communitylist = Community.approved.all(:order => 'name')
    when 'institution'
      communitylist = Community.institution.all(:order => 'name')
    when 'usercontributed'
      communitylist = Community.usercontributed.all(:order => 'name')
    when 'launched'
      communitylist = Community.launched.all(:order => 'name')
    when 'publishing'
      communitylist = Community.all(:conditions => ["entrytype = #{Community::APPROVED} or (entrytype = #{Community::USERCONTRIBUTED} and show_in_public_list = 1)"], :order => 'name')      
    else
      returnhash = {:success => false, :errormessage => 'Unrecognized communitytype.'}
      return render :text => returnhash.to_json
    end  
    
    returnhash[:communitycount] = communitylist.length
    communitylist.each do |community|
      returnhash[:communities][community.id] = {}
      # add in the community information
      returnhash[:communities][community.id][:name] = community.name
      returnhash[:communities][community.id][:entrytype] = community.entrytype_to_s 
      returnhash[:communities][community.id][:shortname] = community.shortname if(!community.shortname.blank?)
      returnhash[:communities][community.id][:description] = community.description if(!community.description.blank?)
      returnhash[:communities][community.id][:public_name] = community.public_name if(!community.public_name.blank?)
      returnhash[:communities][community.id][:primary_content_tag_name] = community.primary_content_tag_name if(!community.primary_content_tag_name.blank?)
      returnhash[:communities][community.id][:content_tag_names] = community.content_tag_names if(!community.content_tag_names.blank?)
      returnhash[:communities][community.id][:launched] = true if(!community.is_launched?)
    end
    return render :text => returnhash.to_json
  end
  
end