# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Api::GvizController < ApplicationController
  # if we are using rails-footnotes, then 
  # stop using it for the data controller
  if defined?(Footnotes::Filter)
    skip_after_filter Footnotes::Filter
  end
  
  def activitytable
    error = false
    errors = []
    filteredparams = ParamsFilter.new([:datatype,:graphtype,:tqx],params)
    datatype =  filteredparams.datatype || 'hourly'
    graphtype = filteredparams.graphtype || ((datatype == 'weekday' or datatype == 'hourly') ? 'column' : 'area') 
     
    tqxparams = filteredparams.tqx
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