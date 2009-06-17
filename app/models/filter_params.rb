# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class FilterParams < ParamExtensions::ParamsFilter
  
  # -----------------------------------
  # instance methods
  # -----------------------------------
  # per specification
  ALLOWED_GDATA_ALT_TYPES = ['atom','rss','json','json-in-script','atom-in-script','rss-in-script']

  # -----------------------------------
  # filtered parameters
  # -----------------------------------
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
  wantsparameter :activity, :string
  wantsparameter :activitygroup, :string
  wantsparameter :activitydisplay, :string
  
  
  wantsparameter :ignorecommunity, :community
  wantsparameter :communityactivity, :string

  wantsparameter :forcecacheupdate, :boolean, false
  
  # graphing/data/gviz api related
  wantsparameter :datatype, :string
  wantsparameter :graphtype, :string
  wantsparameter :tqx, :string
  
  
  # gdata params - some are quoted because symbols can't have dashes
  wantsparameter :author, :user
  wantsparameter 'published-min', :datetime  # note, does not validate for RFC 3339 format per spec.
  wantsparameter 'published-max', :datetime  # note, does not validate for RFC 3339 format per spec.
  wantsparameter 'updated-min', :datetime # note, does not validate for RFC 3339 format per spec.
  wantsparameter 'updated-max', :datetime # note, does not validate for RFC 3339 format per spec.
  wantsparameter :alt, :string
  wantsparameter 'max-results', :integer
  wantsparameter 'start-index', :integer
  wantsparameter :prettyprint, :boolean  # not sure that we'll actually do anything with this
  wantsparameter :strict, :boolean  # not sure that we'll actually do anything with this
  wantsparameter :q, :string # TODO: parse for terms and phrases, and negative values
  wantsparameter :category, :string # TODO: parse for ANDs and ORs (ANDs = ',' ORs = | )

  attr_accessor :additional_options
  
  def initialize(parameters = nil)
    @additional_options = Hash.new
    super
  end
  
  # -----------------------------------
  # instance methods
  # -----------------------------------

  # ------------ sanity checking for parameters -----------
  
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
  
  # sanity check of gdata 'alt' parameter
  def alt
    if(ALLOWED_GDATA_ALT_TYPES.include?(read_parameter(:alt)))
      return read_parameter(:alt)
    else
      return nil
    end
  end
    
  def order(defaultcolumns=nil,defaultdirection='ASC')
    if(read_parameter(:order).nil?)
      # check orderby and sortorder
      tmpdirection = read_parameter(:sortorder)
      returncolumns = read_parameter(:orderby)
    else
      (returncolumns,tmpdirection) = read_parameter(:order).split(' ')
    end
    
    if(returncolumns.blank?)
      if(defaultcolumns.nil?) 
        return nil
      else
        returncolumns = defaultcolumns
      end
    end
    
    if(tmpdirection.blank?)
      if(defaultdirection.nil?)
        return nil
      else
        tmpdirection = defaultdirection
      end
    end
    
    # sanitycheck direction
    if(['d','descending','desc'].include?(tmpdirection.downcase))
      returndirection = 'DESC'
    else
      returndirection = defaultdirection
    end
    
    return "#{returncolumns} #{returndirection}"
  end
  
  def tqx
    if(read_parameter(:tqx).nil?)
      return {}
    else
      returnhash = {}
      read_parameter(:tqx).split(';').each do |keyval|
        key,value = keyval.split(':')
        returnhash[:key] = value
      end
      return returnhash
    end
  end
  
  # ---------- end sanity checking for parameters ---------
  
  def add_option(key,value)
    @additional_options[key] = value
  end
  
  def option_values_hash(options = {})
    validate_wanted_parameters = (options[:validate_wanted_parameters].nil? ? true : options[:validate_wanted_parameters])
    include_unfiltered_parameters = (options[:include_unfiltered_parameters].nil? ? false : options[:include_unfiltered_parameters])
    include_additional_options = (options[:include_additional_options].nil? ? false : options[:include_additional_options])
    
    returnhash = {}
    
    if(include_additional_options)
      @additional_options.each do |key,value|
        returnhash[key.to_sym] = value
      end
    end
    
    if(include_unfiltered_parameters)
      @unfilteredparameters.each do |key,value|
        returnhash[key.to_sym] = value
      end
    end
    
    if(!validate_wanted_parameters)
      @filteredparameters.each do |key,value|
        if(!value.nil?)
          returnhash[key.to_sym] = value
        end
      end
    else
      @filteredparameters.each do |key,value|
        if(!value.nil? and (returnvalue = self.send(key)))
          returnhash[key.to_sym] = returnvalue
        end
      end
    end
    
    return returnhash
  end
  
  # this is a compatibility function to have the @findoptions = check_for_filters continue to work
  def findoptions
    findoptions = {}
    @filteredparameters.each do |key,value|
      if(!value.nil? and (returnvalue = self.send(key)))
        findoptions[key.to_sym] = returnvalue
      end
    end
    return findoptions
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