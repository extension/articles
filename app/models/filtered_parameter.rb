# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class FilteredParameter
  TRUE_PARAMETER_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES'].to_set
  FALSE_PARAMETER_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO'].to_set

  # per gdata specification
  ALLOWED_GDATA_ALT_TYPES = ['atom','rss','json','json-in-script','atom-in-script','rss-in-script']
  
  # content types
  ALLOWED_CONTENT_TYPES = ['articles','faqs','events']

  # recognized names and types
  RECOGNIZED_PARAMETERS = {}
  RECOGNIZED_PARAMETERS[:community] = :community
  RECOGNIZED_PARAMETERS[:location] = :location
  RECOGNIZED_PARAMETERS[:county] = :county
  RECOGNIZED_PARAMETERS[:position] = :position
  RECOGNIZED_PARAMETERS[:institution] = :institution
  RECOGNIZED_PARAMETERS[:person] = :user  # todo: change to method to recognize aliases
  RECOGNIZED_PARAMETERS[:account] = :account  
  RECOGNIZED_PARAMETERS[:dateinterval] = :string 
  RECOGNIZED_PARAMETERS[:datefield] = :string 
  RECOGNIZED_PARAMETERS[:tz] = :string
  RECOGNIZED_PARAMETERS[:limit] = :integer
  RECOGNIZED_PARAMETERS[:order] = :method # caller is responsible for collapsing orderby and sortorder into order
  RECOGNIZED_PARAMETERS[:forcecacheupdate] = {:datatype => :boolean, :default => false} 
  RECOGNIZED_PARAMETERS[:apikey] = :apikey
  RECOGNIZED_PARAMETERS[:tags] = :taglist
  RECOGNIZED_PARAMETERS[:content_types] = :method
  
  
  # AaE params
  RECOGNIZED_PARAMETERS[:squid] = :submitted_question
    
  # TODO: review this vis-a-vis dateinterval and datefield
  RECOGNIZED_PARAMETERS[:datadate] = :date
  
  # TODO: review, some of these are used sparingly in the application and may not really belong here as "standard" parameters
  RECOGNIZED_PARAMETERS[:connectiontype] = :string
  RECOGNIZED_PARAMETERS[:communitytype] = :string # probably should be a method to filter known types
  RECOGNIZED_PARAMETERS[:agreementstatus] = :boolean
  RECOGNIZED_PARAMETERS[:announcements] = :boolean
  RECOGNIZED_PARAMETERS[:source] = :string
  RECOGNIZED_PARAMETERS[:status] = :string
  RECOGNIZED_PARAMETERS[:legacycategory] = :category
  RECOGNIZED_PARAMETERS[:appname] = :string 
  RECOGNIZED_PARAMETERS[:activityapplication] = :activity_application 
  RECOGNIZED_PARAMETERS[:activityentrytype] = :string 
  RECOGNIZED_PARAMETERS[:activityaddress] = :string 
  RECOGNIZED_PARAMETERS[:activity] = :activity 
  RECOGNIZED_PARAMETERS[:activitygroup] = :activitygroup 
  RECOGNIZED_PARAMETERS[:activitydisplay] = :string 
  RECOGNIZED_PARAMETERS[:ignorecommunity] = :community
  RECOGNIZED_PARAMETERS[:communityactivity] = :string 
  # graphing/data/gviz api related
  RECOGNIZED_PARAMETERS[:datatype] = :string 
  RECOGNIZED_PARAMETERS[:graphtype] = :string 
  RECOGNIZED_PARAMETERS[:tqx] = :method 
  # gdata params - symbols can't have dashes, hence the underscores here
  # it's recommended that anything parsing the inbound request params
  # add a compatibility layer to handle params that have dashes to comply
  # with the gdata parameter names.  
  #
  # e.g.  params['updated-min'] would set updated_min 
  #
  RECOGNIZED_PARAMETERS[:author] = :user  # todo: change to method to recognize aliases
  RECOGNIZED_PARAMETERS[:published_min] = :datetime  # note, does not validate for RFC 3339 format per spec.
  RECOGNIZED_PARAMETERS[:published_max] = :datetime  # note, does not validate for RFC 3339 format per spec.
  RECOGNIZED_PARAMETERS[:updated_min] = :datetime  # note, does not validate for RFC 3339 format per spec.
  RECOGNIZED_PARAMETERS[:updated_max] = :datetime  # note, does not validate for RFC 3339 format per spec.
  RECOGNIZED_PARAMETERS[:alt] = :gdata_alt 
  RECOGNIZED_PARAMETERS[:max_results] = :integer 
  RECOGNIZED_PARAMETERS[:start_index] = :integer 
  RECOGNIZED_PARAMETERS[:prettyprint] = :boolean # not sure that we'll actually ever do anything with this
  RECOGNIZED_PARAMETERS[:strict] = :boolean # not sure that we'll actually ever do anything with this
  RECOGNIZED_PARAMETERS[:q] = :string # TODO: parse for terms and phrases, and negative values - if we stay with spec
  RECOGNIZED_PARAMETERS[:category] = :taglist # TODO: parse for ANDs and ORs (ANDs = ',' ORs = | ) - if we stay with spec
  # end: TODO: review
  
  attr_reader :name, :default, :providedvalue, :datatype, :required, :options
  
  def initialize(name, providedvalue, providedoptions = {})
    @options = providedoptions.dup
    @name = name
    @providedvalue = providedvalue
    @required = @options.delete(:required) || false  # TODO: handle required situation? or caller handles?
    @datatype = @options.delete(:datatype)
    @default = @options.delete(:default)
    
    # datatype handling
    if(@datatype.nil? or @datatype == :auto)
      if(RECOGNIZED_PARAMETERS[name].blank?)
        @datatype = nil
      else
        if(RECOGNIZED_PARAMETERS[name].is_a?(Symbol))
          @datatype = RECOGNIZED_PARAMETERS[name]
        elsif(RECOGNIZED_PARAMETERS[name].is_a?(Hash))
          @datatype = RECOGNIZED_PARAMETERS[name][:datatype]
          if(@default.nil? and !(RECOGNIZED_PARAMETERS[name][:default].nil?))
            @default = RECOGNIZED_PARAMETERS[name][:default]
          else
            @default = @default
          end
        else
          @datatype = nil
        end
      end      
    end
  end
  
  def unfiltered 
    return nil if(providedvalue.nil? and default.nil?)
    (providedvalue.nil? ? default : providedvalue)
  end
    
  # Casts value (which is a String coming from the parameters) to an appropriate instance.
  def filtered
    value = self.unfiltered
    return nil if value.nil?
    case datatype
    when :method
      if(self.class.method_defined?("filter_#{name}"))
        self.send("filter_#{name}",value)
      else
        nil # TODO: raise error?
      end
    when :string      
      value
    when :integer     
      value.to_i rescue value ? 1 : 0
    when :float       
      value.to_f
    when :datetime
      begin    
        Time.zone.parse(value) 
      rescue 
        nil # TODO: raise invalid error
      end 
    when :date
      begin        
        Time.zone.parse(value).to_date 
      rescue 
        nil # TODO: raise invalid error
      end
    when :boolean     
      self.class.value_to_boolean(value)
    when :serialized
      begin  
        YAML::load(Base64.decode64(value))
      rescue 
        nil # TODO: raise invalid error
      end
    when :community   
      Community.find_by_id_or_name_or_shortname(value)
    when :location    
      Location.find_by_id(value)
    when :county      
      County.find_by_id(value)
    when :position    
      Position.find_by_id(value)
    when :user        
      User.find_by_email_or_extensionid_or_id(value)
    when :account        
      Account.find_by_email_or_extensionid_or_id(value,false)
    when :category    
      Category.find_by_name_or_id(value)
    when :submitted_question
      SubmittedQuestion.find_by_id(value)
    when :activity_application 
      ActivityApplication.find_by_id(value)
    when :activity
      if(activitycodes = Activity.activity_to_codes(value))
        return value
      else
        return nil # TODO: raise invalid error
      end
    when :activitygroup
      if(activitytypes = Activity.activitygroup_to_types(value))
        return value
      else
        return nil # TODO: raise invalid error
      end
    when :gdata_alt
      if(ALLOWED_GDATA_ALT_TYPES.include?(value))
        return value
      else
        return nil # TODO: raise invalid error
      end
    when :apikey
      ApiKey.find_by_keyvalue(value)
    when :taglist
       return Tag.castlist_to_array(value.gsub('|',','),true,false)
    else
      nil # TODO: raise invalid datatype error
    end
  end

  def number?
    datatype == :integer || datatype == :float 
  end
  
  def filter_order(value)
    defaultcolumns = @options[:defaultcolumns] || nil
    defaultdirection = @options[:defaultdirection] || 'ASC'
    (returncolumns,tmpdirection) = value.split(' ')
    
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
  
  def filter_tqx(value)
    if(value.nil?)
      return {}
    else
      returnhash = {}
      value.split(';').each do |keyval|
        key,value = keyval.split(':')
        returnhash[:key] = value
      end
      return returnhash
    end
  end
  
   def filter_content_types(value)
      returnarray = []
      if(value.blank?)
         return nil
      else
         list = value.split(Regexp.new(/\s*,\s*/)).collect{|item| item.strip}
         list.each do |content_type|
            if(ALLOWED_CONTENT_TYPES.include?(content_type))
               returnarray << content_type
            end
         end
         if returnarray.blank?
            return nil
         end
      end
      return returnarray.compact.uniq
   end
         
  
  # if datatype is a taglist
  # return whether it included a | anywhere
  # which we'll treat as "or" 
  # otherwise, treat it as an and?
  def taglist_operator
     if(@datatype == :taglist)
        if(self.unfiltered.include?('|'))
           return 'or'
        else
           return 'and'
        end
     else
        return nil
     end
  end
  

  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self

    # convert something to a boolean
    def value_to_boolean(value)
      if value.is_a?(String) && value.blank?
        nil
      else
        TRUE_PARAMETER_VALUES.include?(value)
      end
    end

  end
end # FilteredParameter