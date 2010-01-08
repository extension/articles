# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class DataController < ApplicationController
  layout 'people'
  before_filter :login_optional
  
  # if we are using rails-footnotes, then 
  # stop using it for the data controller
  if defined?(Footnotes::Filter)
    skip_after_filter Footnotes::Filter
  end
  
  def activitytable
    error = false
    errors = []
    @filteredparams = FilterParams.new(params)
        
    datatype =  @filteredparams.datatype || 'hourly'
    graphtype = @filteredparams.graphtype || ((datatype == 'weekday' or datatype == 'hourly') ? 'column' : 'area') 
     
    tqxparams = @filteredparams.tqx
    responseHandler = params[:responseHandler] || "google.visualization.Query.setResponse"
    version = 0.5
    reqId = tqxparams['reqId'] || 0

    comparisons = check_for_table_comparisons
    if(comparisons.blank?)
      @findoptions = @filteredparams.findoptions
      @activity = ActivityContainer.new({:findoptions => @findoptions, :datatype => datatype, :graphtype => graphtype, :forcecacheupdate => @filteredparams.forcecacheupdate})
      @json_data_table = @activity.table
    else
      containers = []
      comparisons.each do |comparison|
        containers << ActivityContainer.new({:findoptions => comparison, :datatype => datatype, :graphtype => graphtype, :forcecacheupdate => @filteredparams.forcecacheupdate})
      end
      normalize = params[:normalize].nil? ? false : (params[:normalize] == 'true')
      @json_data_table = ActivityContainer.comparisontable(containers,normalize)
    end
    json_output_string = "#{responseHandler}({reqId: '#{reqId}',"
    if(error)
      json_output_string += "status:'error',errors:[#{errors.join(',')}]"
    else
      json_output_string += "status:'ok',table:#{@json_data_table}"
    end
    json_output_string += ",version: '#{version}'})"
    render :text => json_output_string
  end
  
  def publicprofile
    filteredparams = ParamsFilter.new([:person,:apikey],params)
    if(filteredparams.apikey.nil?)
      returnhash = {:success => false, :errormessage => 'Invalid api key'}
      return render :text => returnhash.to_json
    end
    # TODO: consider doing this automatically in application_controller as a before_filter
    ApiKeyEvent.log_event("#{controller_path}/#{action_name}",filteredparams.apikey)
    
    if(filteredparams.person.nil?)
      returnhash = {:success => false, :errormessage => 'No show user.'}
      return render :text => returnhash.to_json
    else
      @showuser = filteredparams.person
    end
    
    publicattributes = @showuser.public_attributes
    if(publicattributes.nil?)
      returnhash = {:success => false, :errormessage => 'No public attributes'}
      return render :text => returnhash.to_json
    else
      returnhash = publicattributes.merge({:success => true})
      return render :text => returnhash.to_json
    end
  end
  
  def launchedcommunities
    filteredparams = ParamsFilter.new([:apikey],params)
    if(filteredparams.apikey.nil?)
      returnhash = {:success => false, :errormessage => 'Invalid api key'}
      return render :text => returnhash.to_json
    end
    # TODO: consider doing this automatically in application_controller as a before_filter
    ApiKeyEvent.log_event("#{controller_path}/#{action_name}",filteredparams.apikey)
    
    returnhash = {:success => true, :items => {}, :version => 1}
    communitylist = Community.launched.all(:order => 'name')
    returnhash[:itemcount] = communitylist.length
    communitylist.each do |community|
      returnhash[:items][community.id] = {:name => community.name, :public_name => community.public_name, :primary_content_tag_name => community.primary_content_tag_name, :content_tag_names => community.content_tag_names}
    end
    return render :text => returnhash.to_json
  end
  
  def aae_numbers
    filteredparams = FilterParams.new(params)
    # just going to get them for a single user for now
    if(filteredparams.person.nil?)
      returnhash = {:success => false, :errormessage => 'Not a valid account'}
      return render :text => returnhash.to_json
    end
    
    returnhash = {}
    returnhash[:total_incoming] = SubmittedQuestion.submitted.count
    returnhash[:answered] = SubmittedQuestion.resolved.filtered({:resolved_by => filteredparams.person}).count
    returnhash[:assigned] = SubmittedQuestion.submitted.filtered({:assignee => filteredparams.person}).count
    filteroptions = filteredparams.person.aae_filter_prefs
    # skip the joins because we are including them already with listdisplayincludes
    returnhash[:filtered_incoming] = SubmittedQuestion.submitted.filtered(filteroptions).count
    return render :text => returnhash.to_json
  end
  
  protected
  
  def check_for_table_comparisons
    allowed_params = ['primary','secondary','tertiary','quaternary','quinary','senary','septenary']
    comparisons = []
    @filteredparams = FilterParams.new(params)
    baseoptions = @filteredparams.findoptions
    
    
    if(params[:primary_type].nil? or params[:primary_id].nil?)
      return nil
    end
    
    allowed_params.each do |order|
      typeparam = "#{order}_type".to_sym
      idparam = "#{order}_id".to_sym
      if(!params[typeparam].nil? and !params[idparam].nil?)
        if(objhash = get_comparison_object(params[typeparam],params[idparam]))
          comparisons << baseoptions.merge(objhash)
        end
      end
    end    
    return comparisons
  end
  
  # returns a hash of {:object => object} - although {:dateinterval => value} is not an object
  def get_comparison_object(type,id)
    case type
    when 'person'
      # only process this when logged in
      # TODO: change when user activity is allowed to be public
      # if(!@currentuser.nil?)        
        if(id.to_i != 0)
          returnobj = User.find_by_id(id)
        else
          returnobj = User.find_by_login(id)
        end
        datalabel = (returnobj.nil? ? "Person: #{id}" : returnobj.fullname)
      # else
      #   return nil
      # end
    when 'community'
      returnobj = Community.find_by_id(id)
      datalabel = (returnobj.nil? ? "Community: #{id}" : returnobj.name)
    when 'location'
      returnobj = Location.find_by_id(id)
      datalabel = (returnobj.nil? ? "Location: #{id}" : returnobj.name)
    when 'county'
      returnobj = County.find_by_id(id)
      datalabel = (returnobj.nil? ? "County: #{id}" : returnobj.name)
    when 'position'
      returnobj = Position.find_by_id(id)
      datalabel = (returnobj.nil? ? "Position: #{id}" : returnobj.name)                   
    when 'dateinterval'
      returnobj = id
      datalabel = "DateInterval: #{id}"
    when 'activity'
      returnobj = id
      datalabel = "Activity: #{id}"
    else
      returnobj = nil
    end
  
    if(returnobj.nil?)
      return nil
    else
      return {type.to_sym => returnobj, :datalabel => datalabel}
    end
  end
  
end