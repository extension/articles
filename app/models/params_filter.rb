# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


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
      #
      # otherwise, create a .name method that returns nil
      # and a .name? method that returns false
      if(!provided_parameters[name].nil?)
        @filtered_parameters[name] = FilteredParameter.new(name,provided_parameters[name],options)
        (class << self; self; end).class_eval do
          define_method name do 
            @filtered_parameters[name].filtered
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

end