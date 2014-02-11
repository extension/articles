# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file


# A class that will parse through the provided_parameters (meant to be ActionController#params) 
# - and will create instance methods based on the desired filtered_list - calling FilteredParameter#filtered
# for the actual output - see the FilteredParameter class for more information
#
# ==== Method arguments
#  filtered_list:: an array of symbols that match an entry in FilteredParameter::RECOGNIZED_PARAMETERS to filter 
#  in the parameters e.g. [:person,:apikey].  For values that are not in FilteredParameter::RECOGNIZED_PARAMETERS 
#  the array value should be a single keyed hash with options for the datatype to filter and other options
#  e.g.  [:person,:apikey,{:customparameter => :community}] or [:person,:apikey,{:customparameter => {:datatype => :community}}]
#  You can also override recognized defaults using the hash.  e.g. [{:person => :string},:apikey]
#
#  provided_parameters:: a hash of the key => value pairs to filter - expects ActionController#params
# ==== Examples
#
# >> params = {:person => 'jayoung',:apikey =>'test'}
# => {:person=>"jayoung", :apikey=>"test"}
# >>     filteredparams = ParamsFilter.new([:person,:apikey,:community],params)
# => #<ParamsFilter:0x1065b92d8 @filtered_parameters={:person=>#<FilteredParameter:0x10659d650 ...>
# >> filteredparams.person
# => #<User id: 11, login: "jayoung" ...>
# >> filteredparams.person?
# => true
# >> filteredparams.community?
# => false
# >> filteredparams.community
# => nil
#
class ParamsFilter
  
  def initialize(filtered_list, provided_parameters)
    @filtered_parameters = {}
    filtered_list.each do |item|
      if(item.is_a?(Symbol))
        name = item
        options = {:datatype => :auto}
      elsif(item.is_a?(Hash))
        # we only allow a single keyed hash here
        # with parameter name => datatype|options
        name = item.keys[0]
        if(item[name].is_a?(Symbol))
          options = {:datatype => item[name]}
        elsif(item[name].is_a?(Hash))
          options = item[name]
        end
      end
      
      # check provide parameters for existence of name
      # if there, add as FilteredParameter to my filtered_parameters list
      # and create .name method that returns the filtered parameter 
      # and create a .name? method that returns 'true' that we have the param
      # and create a ._name method that returns the FilteredParameter object
      #
      # also check for the "dash version of underscored names"
      # e.g. look for 'updated-min' for names that are 'updated_min'
      # otherwise known as 'gdata compatibility mode'
      #
      # otherwise, create a .name method that returns nil
      # and a .name? method that returns false
      if(!provided_parameters[name].nil?)
        @filtered_parameters[name] = FilteredParameter.new(name,provided_parameters[name],options)
        (class << self; self; end).class_eval do
           define_method name do 
             @filtered_parameters[name].filtered
           end
           
           define_method "_#{name}" do 
             @filtered_parameters[name]
           end
       
          define_method "#{name}?" do 
            true
          end
        end
      elsif(!provided_parameters[name.to_s.tr('_','-')].nil?)
        @filtered_parameters[name] = FilteredParameter.new(name,provided_parameters[name.to_s.tr('_','-')],options)
        (class << self; self; end).class_eval do
          define_method name do 
            @filtered_parameters[name].filtered
          end
          
          define_method "_#{name}" do 
            @filtered_parameters[name]
          end
          
          define_method "#{name}?" do 
            true
          end
        end
      elsif(options[:default])
        @filtered_parameters[name] = FilteredParameter.new(name,nil,options)
        (class << self; self; end).class_eval do
          define_method name do 
            @filtered_parameters[name].filtered
          end
          
          define_method "_#{name}" do 
            @filtered_parameters[name]
          end
          
          define_method "#{name}?" do 
            true
          end
        end
      else
        (class << self; self; end).class_eval do
          define_method name do 
            nil
          end
          
          define_method "#{name}?" do 
            false
          end
        end
      end
    end
  end
  
  
  # outputs a string of filter settings
  # TODO: refactor
  # TODO: facilitate item linking, perhaps
  # This is a backwards compatibility function to the old fiter_params model
  def filter_string(options={})
    returnarray = []
    show_community_connection_type = options[:show_community_connection_type].nil? ? true :  options[:show_community_connection_type]
    show_community = options[:show_community].nil? ? true :  options[:show_community_connection_type]
    
    
    @filtered_parameters.keys.each do |param|
      if(show_community and @filtered_parameters[param].class == 'Community')
        returnarray << "#{param.to_s}: #{@filtered_parameters[param].name}"
      elsif(show_community_connection_type and param.to_s == 'connectiontype' or param.to_s == 'communitytype')
        if(param.to_s == 'connectiontype')
          returnarray << "community connection: #{@filtered_parameters[param].unfiltered}"
        end
        
        if(param.to_s == 'communitytype')
          returnarray << "community type: #{@filtered_parameters[param].unfiltered}"
        end
      else
        if(param.to_s != 'connectiontype' and param.to_s != 'communitytype' and @filtered_parameters[param].class != 'Community')
          returnarray << "#{param.to_s}: #{@filtered_parameters[param].unfiltered}"
        end
      end
        
    end

    if(!returnarray.blank?)      
      return "Filtered by: #{returnarray.sort.join(' | ')}"
    else
      return ''
    end
  end
  
  # this is a compatibility function to have the @findoptions = check_for_filters continue to work
  def findoptions
    findoptions = {}
    @filtered_parameters.keys.each do |param|
      findoptions[param] = @filtered_parameters[param].filtered
    end
    return findoptions
  end
  

  def option_values_hash(filter = true)
    returnhash = {}
    
    if(!filter)
      @filtered_parameters.each do |key,value|
        returnhash[key] = value.unfiltered
      end
    else
      @filtered_parameters.each do |key,value|
        returnvalue = value.filtered
        if(!returnvalue.nil?)
          returnhash[key] = returnvalue
        end
      end
    end
    
    return returnhash
  end

end