# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class DataController < ApplicationController
  layout 'people'
  before_filter :login_optional
  if defined?(Footnotes::Filter)
    skip_after_filter Footnotes::Filter
  end
  
  def activitytable
    error = false
    errors = []
    
    forcecacheupdate = params[:forcecacheupdate].nil? ? false : (params[:forcecacheupdate] == 'true')
    datatype = params[:datatype].nil? ? 'hourly' : params[:datatype]
    graphtype = params[:graphtype].nil? ? ((datatype == 'weekday' or datatype == 'hourly') ? 'column' : 'area') : params[:graphtype]
     
    tqxparams = get_tqx_params(params)
    responseHandler = params[:responseHandler] || "google.visualization.Query.setResponse"
    version = 0.5
    reqId = tqxparams['reqId'] || 0

    comparisons = check_for_table_comparisons
    if(comparisons.blank?)
      @filteredparams = FilterParams.new(params)
      @findoptions = @filteredparams.findoptions
      
      @activity = ActivityContainer.new({:findoptions => @findoptions, :datatype => datatype, :graphtype => graphtype, :forcecacheupdate => forcecacheupdate})
      @json_data_table = @activity.table
    else
      containers = []
      comparisons.each do |comparison|
        containers << ActivityContainer.new({:findoptions => comparison, :datatype => datatype, :graphtype => graphtype, :forcecacheupdate => forcecacheupdate})
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
    if(!params[:userid].nil?)
      @showuser = User.find_by_id(params[:userid])
    elsif(!params[:extensionid].nil?)
      @showuser = User.find_by_login(params[:extensionid])
    elsif(!params[:email].nil?)
      @showuser = User.find_by_email(params[:email])
    end
    
    if(@showuser.nil?)
      returnhash = {:success => false, :errormessage => 'No show user.'}
      return render :text => returnhash.to_json
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
  
  protected
  
  def get_tqx_params(params)
    returnhash = {}
    if(params[:tqx].nil?)
      return returnhash
    end
    
    params[:tqx].split(';').each do |keyval|
      key,value = keyval.split(':')
      returnhash[:key] = value
    end
    
    return returnhash
  end
  
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
    when 'institution'
      returnobj = Institution.find_by_id(id)
      datalabel = (returnobj.nil? ? "Institution: #{id}" : returnobj.name)
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