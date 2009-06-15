# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module ParamExtensions

    class MissingParameterError < NoMethodError
    end

    class WantedParameter
      TRUE_PARAMETER_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES'].to_set
      FALSE_PARAMETER_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO'].to_set


      attr_reader :name, :default, :datatype, :null

      def initialize(name, datatype, default = nil, null = true)
        @name, @datatype, @default, @null,  = name, datatype, default, null
      end


      # Casts value (which is a String coming from the parameters) to an appropriate instance.
      def type_cast(value)
        return nil if value.nil?
        case datatype
          when :string      then value
          when :integer     then value.to_i rescue value ? 1 : 0
          when :float       then value.to_f
          when :datetime    then Time.zone.parse(value) rescue nil 
          when :date        then Time.zone.parse(value).to_date rescue nil 
          when :boolean     then self.class.value_to_boolean(value)
          when :serialized  then YAML::load(Base64.decode64(value)) rescue nil
          when :community   then Community.find_by_id(value)
          when :location    then Location.find_by_id(value)
          when :county      then County.find_by_id(value)
          when :position    then Position.find_by_id(value)
          when :institution then Institution.find_by_id(value)
          when :user        then User.find_by_email_or_extensionid_or_id(value)
          when :activity_application then ActivityApplication.find_by_id(value)
          else value
        end
      end

      def type_cast_code(var_name)
        case datatype
          when :string    then nil
          when :integer   then "(#{var_name}.to_i rescue #{var_name} ? 1 : 0)"
          when :float     then "#{var_name.to_f}"
          when :datetime  then "(Time.zone.parse(#{var_name}) rescue nil)"
          when :date      then "(Time.zone.parse(#{var_name}).to_date rescue nil)"
          when :boolean   then "#{self.class.name}.value_to_boolean(#{var_name})"
          when :serialized then "(YAML::load(Base64.decode64(#{var_name})) rescue nil)"
          when :community  then "Community.find_by_id(#{var_name})"
          when :location   then "Location.find_by_id(#{var_name})"
          when :county     then "County.find_by_id(#{var_name})"
          when :position   then "Position.find_by_id(#{var_name})"
          when :institution then "Institution.find_by_id(#{var_name})"
          when :user       then "User.find_by_email_or_extensionid_or_id(#{var_name})"
          when :activity_application then "ActivityApplication.find_by_id(#{var_name})"
          else nil
        end
      end

      def number?
        datatype == :integer || datatype == :float 
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

    class ParamsFilter 

      def initialize(parameters = nil)
        @filteredparameters = {}
        @unfilteredparameters = {}
        @filteredparameters = filteredparameters_from_wantedparameters_definition
        self.filteredparameters = parameters unless parameters.nil?
        result = yield self if block_given?
        result
      end

      def [](parameter_name)
        read_parameter(parameter_name)
      end

      # Updates the attribute identified by <tt>attr_name</tt> with the specified +value+.
      # (Alias for the protected write_attribute method).
      def []=(parameter_name, value)
        write_parameter(parameter_name, value)
      end

      def filteredparameters=(new_parameters)
        return if new_parameters.nil?
        parameters = new_parameters.dup
        parameters.stringify_keys!
          
        parameters.each do |k, v|
          respond_to?(:"#{k}=") ? send(:"#{k}=", v) : @unfilteredparameters[k] = v
        end   
      end
      
      
      def filteredparameters
        self.filtereredparameter_names.inject({}) do |parameters, name|
          parameters[name] = read_parameter(name)
          parameters
        end
      end
      
      
      def filteredparameters_before_type_cast
        self.filtereredparameter_names.inject({}) do |parameters, name|
          parameters[name] = read_parameter_before_type_cast(name)
          parameters
        end
      end
      
      def filtereredparameter_names
        @filteredparameters.keys.sort
      end

      def method_missing(method_id, *args, &block)
        method_name = method_id.to_s

        # private_method_defined? is a ruby module method
        if self.class.private_method_defined?(method_name)
          raise NoMethodError.new("Attempt to call private method", method_name, args)
        end

        # If we haven't generated any methods yet, generate them, then
        # see if we've created the method we're looking for.
        if !self.class.generated_methods?
          self.class.define_parameter_methods
          if self.class.generated_methods.include?(method_name)
            return self.send(method_id, *args, &block)
          end
        end

        if md = self.class.match_parameter_method?(method_name)
          parameter_name, method_type = md.pre_match, md.to_s
          if @filteredparameters.include?(parameter_name)
            __send__("parameter#{method_type}", parameter_name, *args, &block)
          else
            super
          end
        elsif @filteredparameters.include?(method_name)
          read_parameter(method_name)
        else
          super
        end
      end

      def read_parameter(parameter_name)
        parameter_name = parameter_name.to_s
        if !(value = @filteredparameters[parameter_name]).nil?
          if wantedparameter = wantedparameter_for_filteredparameter(parameter_name)
            wantedparameter.type_cast(value)
          else
            value
          end
        else
          nil
        end
      end

      def read_parameter_before_type_cast(parameter_name)
        @filteredparameters[parameter_name]
      end

      def write_parameter(parameter_name, value)
        parameter_name = parameter_name.to_s
        if (wantedparameter = wantedparameter_for_filteredparameter(parameter_name)) && wantedparameter.number?
          @filteredparameters[parameter_name] = convert_number_column_value(value)
        else
          @filteredparameters[parameter_name] = value
        end
      end

      def wantedparameter_for_filteredparameter(name)
        self.class.wantedparameters_hash[name.to_s]
      end

      def query_parameter(parameter_name)
        unless value = read_parameter(parameter_name)
          false
        else
          wantedparameter = self.class.wantedparameters_hash[parameter_name]
          if wantedparameter.nil?
            if Numeric === value || value !~ /[^0-9]/
              !value.to_i.zero?
            else
              return false if ParamExtensions::WantedParameter::FALSE_PARAMETER_VALUES.include?(value)
              !value.blank?
            end
          elsif wantedparameter.number?
            !value.zero?
          else
            !value.blank?
          end
        end
      end

      def convert_number_column_value(value)
        if value == false
          0
        elsif value == true
          1
        elsif value.is_a?(String) && value.blank?
          nil
        else
          value
        end
      end

      def filteredparameters_from_wantedparameters_definition
        self.class.wantedparameters.inject({}) do |filteredparameters, wantedparameter|
          filteredparameters[wantedparameter.name] = wantedparameter.default
          filteredparameters
        end
      end
  
      def missing_parameter(parameter_name, stack)
        raise ParamExtensions::MissingParameterError, "missing parameter: #{parameter_name}", stack
      end

      # Handle *? for method_missing.
      def parameter?(parameter_name)
        query_parameter(parameter_name)
      end

      # Handle *= for method_missing.
      def parameter=(parameter_name, value)
        write_parameter(parameter_name, value)
      end

      # Handle *_before_type_cast for method_missing.
      def parameter_before_type_cast(parameter_name)
        read_parameter_before_type_cast(parameter_name)
      end
      
      def respond_to?(method, include_private_methods = false)
        method_name = method.to_s
        if super
          return true
        elsif !include_private_methods && super(method, true)
          # If we're here than we haven't found among non-private methods
          # but found among all methods. Which means that given method is private.
          return false
        elsif !self.class.generated_methods?
          self.class.define_parameter_methods
          if self.class.generated_methods.include?(method_name)
            return true
          end
        end

        if @filteredparameters.nil?
          return super
        elsif @filteredparameters.include?(method_name)
          return true
        elsif md = self.class.match_parameter_method?(method_name)
          return true if @filteredparameters.include?(md.pre_match)
        end
        super
      end

      # -----------------------------------
      # Class-level methods
      # -----------------------------------
      class << self

        def wantedparameters_hash
          @wantedparameters_hash ||= wantedparameters.inject({}) { |hash, wantedparameter| hash[wantedparameter.name] = wantedparameter; hash }
        end
        
        # Returns an array of column names as strings.
        def wantedparameter_names
          @wantedparameter_names ||= wantedparameters.map { |wantedparameter| wantedparameter.name }
        end

        def wantedparameters()
          @wantedparameters ||= []
        end

        def wantsparameter(name, datatype, default = nil, null = true)
          wantedparameters << ParamExtensions::WantedParameter.new(name.to_s,datatype,default,null)
        end

        def wantedparameter_methods_hash
          @dynamic_methods_hash ||= wantedparameter_names.inject(Hash.new(false)) do |methods, param|
            param_name = param.to_s
            methods[param.to_sym]       = param_name
            methods["#{param}=".to_sym] = param_name
            methods["#{param}?".to_sym] = param_name
            methods["#{param}_before_type_cast".to_sym] = param_name
            methods
          end
        end
        
        def all_parameters_exists?(parameter_names)
          parameter_names.all? { |name| wantedparameter_methods_hash.include?(name.to_sym) }
        end
        
        def parameter_method_suffix(*suffixes)
          parameter_method_suffixes.concat suffixes
          rebuild_parameter_method_regexp
        end

        # Returns MatchData if method_name is an attribute method.
        def match_parameter_method?(method_name)
          rebuild_parameter_method_regexp unless defined?(@@parameter_method_regexp) && @@parameter_method_regexp
          @@parameter_method_regexp.match(method_name)
        end


        # Contains the names of the generated attribute methods.
        def generated_methods #:nodoc:
          @generated_methods ||= Set.new
        end

        def generated_methods?
          !generated_methods.empty?
        end

        def instance_method_already_implemented?(method_name)
          method_name = method_name.to_s
          return true if (method_name =~ /^id(=$|\?$|$)/)
          @_defined_class_methods ||= (self.public_instance_methods(false) | self.private_instance_methods(false) | self.protected_instance_methods(false) ).map(&:to_s).to_set
          @_defined_class_methods.include?(method_name)
        end        

        def define_parameter_methods
          return if generated_methods?
          wantedparameters_hash.each do |name, wp|
            unless instance_method_already_implemented?(name)
              define_read_method(name.to_sym, name, wp)
            end

            unless instance_method_already_implemented?("#{name}=")
              define_write_method(name.to_sym)
            end

            unless instance_method_already_implemented?("#{name}?")
              define_question_method(name)
            end
          end
        end

        # begin privates
        private

          # Suffixes a, ?, c become regexp /(a|\?|c)$/
          def rebuild_parameter_method_regexp
            suffixes = parameter_method_suffixes.map { |s| Regexp.escape(s) }
            @@parameter_method_regexp = /(#{suffixes.join('|')})$/.freeze
          end

          # Default to =, ?, _before_type_cast
          def parameter_method_suffixes
            @@parameter_method_suffixes ||= []
          end

          def define_read_method(symbol, parameter_name, wantedparameter)
            cast_code = wantedparameter.type_cast_code('v') if wantedparameter
            access_code = cast_code ? "(v=@filteredparameters['#{parameter_name}']) && #{cast_code}" : "@filteredparameters['#{parameter_name}']"
            access_code = access_code.insert(0, "missing_parameter('#{parameter_name}', caller) unless @filteredparameters.has_key?('#{parameter_name}'); ")
            evaluate_parameter_method parameter_name, "def #{symbol}; #{access_code}; end"
          end

          def define_question_method(parameter_name)
            evaluate_parameter_method parameter_name, "def #{parameter_name}?; query_parameter('#{parameter_name}'); end", "#{parameter_name}?"
          end

          def define_write_method(parameter_name)
            evaluate_parameter_method parameter_name, "def #{parameter_name}=(new_value);write_parameter('#{parameter_name}', new_value);end", "#{parameter_name}="
          end

          # Evaluate the definition for an parameter related method
          def evaluate_parameter_method(parameter_name, method_definition, method_name=parameter_name)
            generated_methods << method_name

            begin
              class_eval(method_definition, __FILE__, __LINE__)
            rescue SyntaxError => err
              generated_methods.delete(parameter_name)
              # if logger
              #   logger.warn "Exception occurred during reader method compilation."
              #   logger.warn "Maybe #{parameter_name} is not a valid Ruby identifier?"
              #   logger.warn err.message
              # end
            end
          end

          # end privates
      end #  ClassMethods
    end  
    
    
    # def additionaldata_from_params(params)
    #   additionaldata = params
    #   additionaldata[:remoteaddr] = request.env["REMOTE_ADDR"]
    #   return additionaldata
    # end
    # 
    # def order_from_params(defaultdirection='ASC')
    #   # either going to be "order=columnstring direction" 
    #   # or it will be "orderby=columnstring&sortorder=direction"
    #   if(!params[:order].blank?)
    #     return params[:order]
    #   elsif(!params[:orderby].blank?)
    #     if(!params[:sortorder].blank?)
    #       return "#{params[:orderby]} #{params[:sortorder]}"
    #     else
    #       return "#{params[:orderby]} #{defaultdirection}"
    #     end
    #   else
    #     return nil
    #   end
    # end
    # 
    # #
    # # ToDo:  This really needs to check for array lists
    # # 
    # def check_for_filters
    # 
    #   returnoptions = {}
    # 
    #   # community
    #   if(!params[:community].nil?)
    #     returnoptions[:community] = Community.find_by_id(params[:community])
    #   end
    # 
    #   # location
    #   if(!params[:location].nil?)
    #     returnoptions[:location] = Location.find_by_id(params[:location])
    #   end
    # 
    #   # county
    #   if(!params[:county].nil?)
    #     returnoptions[:county] = Location.find_by_id(params[:county])
    #   end
    #   
    #   # position
    #   if(!params[:position].nil?)
    #     returnoptions[:position] = Position.find_by_id(params[:position])
    #   end
    # 
    #   # institution
    #   if(!params[:institution].nil?)
    #     returnoptions[:institution] = Institution.find_by_id(params[:institution])
    #   end
    # 
    #   # person/user
    #   if(!params[:person].nil?)      
    #     # only process this when logged in
    #     # TODO: change when user activity is allowed to be public
    #     if(!@currentuser.nil?)
    #       if(params[:person].to_i != 0)
    #         returnoptions[:user] = User.find_by_id(params[:person])
    #       elsif(params[:person] == 'me')
    #         returnoptions[:user] = @currentuser
    #       else
    #         returnoptions[:user] = User.find_by_login(params[:person])
    #       end
    #     end
    #   end
    # 
    #   if(!params[:connectiontype].nil?)
    #     if(Communityconnection::TYPES.keys.include?(params[:connectiontype]))
    #       returnoptions[:connectiontype] = params[:connectiontype]
    #     end
    #   end
    # 
    #   if(!params[:communitytype].nil?)
    #     returnoptions[:communitytype] = params[:communitytype]
    #   end
    # 
    #   if(!params[:agreementstatus].nil?)
    #     returnoptions[:agreementstatus] = params[:agreementstatus]
    #   end
    # 
    # 
    # 
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
    #   if(!params[:datecount].nil?)
    #     returnoptions[:datecount] = params[:datecount]
    #   end
    #   
    #   if(!params[:announcements].nil?)
    #     if(params[:announcements] == '1' or params[:announcements] == 'yes')
    #       returnoptions[:announcements] = true
    #     else
    #       returnoptions[:announcements] = false
    #     end
    #   end
    # 
    #   if(!params[:datefield].nil?)
    #     returnoptions[:datefield] = params[:datefield]
    #   end
    # 
    #   if(!params[:tz].nil?)
    #     returnoptions[:tz] = params[:tz]
    #   end
    # 
    #   # user activity specific
    #   if(!params[:activityapplication].nil?)
    #     returnoptions[:activityapplication] = ActivityApplication.find_by_id(params[:activityapplication])
    #   end
    # 
    #   if(!params[:appname].nil?)
    #     returnoptions[:appname] = params[:appname]
    #   end
    # 
    #   if(!params[:activityentrytype].nil?)
    #     returnoptions[:activityentrytype] = params[:activityentrytype]
    #   end
    #   
    #   # ip address
    #   if(!params[:activityaddress].nil?)
    #     returnoptions[:activityaddress] = params[:activityaddress]
    #   end
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
    #   if(!params[:ignorecommunity].nil?)
    #     returnoptions[:ignorecommunity] = Community.find_by_id(params[:ignorecommunity])
    #   end
    # 
    #   if(!params[:communityactivity].nil?)
    #     returnoptions[:communityactivity] = params[:communityactivity]
    #   end              
    #   return returnoptions
    # end
    # 
    # def create_filter_params(options = {})    
    # 
    #   returnparams = {}
    #   if(options.nil?)
    #     return {}
    #   end
    # 
    #   if(!options[:community].nil?)
    #     returnparams[:community] = options[:community].id
    #   end
    # 
    #   if(!options[:institution].nil?)
    #     returnparams[:institution] = options[:institution].id
    #   end
    # 
    #   if(!options[:location].nil?)
    #     returnparams[:location] = options[:location].id
    #   end
    # 
    #   if(!options[:county].nil?)
    #     returnparams[:county] = options[:county].id
    #   end
    #   
    #   if(!options[:position].nil?)
    #     returnparams[:position] = options[:position].id
    #   end
    # 
    #   if(!options[:user].nil?)
    #     returnparams[:person] = options[:user].id
    #   end
    # 
    #   if(!options[:connectiontype].nil?)
    #     returnparams[:connectiontype] = options[:connectiontype]
    #   end
    # 
    #   if(!options[:agreementstatus].nil?)
    #     returnparams[:agreementstatus] = options[:agreementstatus]
    #   end
    # 
    #   if(!options[:communitytype].nil?)
    #     returnparams[:communitytype] = options[:communitytype]
    #   end    
    # 
    #   # dates
    #   if(!options[:dateinterval].nil?)
    #     if(options[:dateinterval].is_a?(Array))
    #       # assume range
    #       returnparams[:dateinterval] = 'range'
    #       returnparams[:datestart] = options[:dateinterval][0]
    #       returnparams[:dateend] = options[:dateinterval][1]
    #     else
    #       returnparams[:dateinterval] = options[:dateinterval]
    #     end
    #   end
    # 
    #   if(!options[:datecount].nil?)
    #     returnparams[:datecount] = options[:datecount]
    #   end
    # 
    #   if(!options[:datefield].nil?)
    #     returnparams[:datefield] = options[:datefield]
    #   end
    # 
    #   if(!options[:tz].nil?)
    #     returnparams[:tz] = options[:tz]
    #   end
    # 
    #   # user activity specific
    #   if(!options[:activityapplication].nil?)
    #     returnparams[:activityapplication] = options[:activityapplication].id
    #   end
    #   
    #   if(!options[:appname].nil?)
    #     returnparams[:appname] = options[:appname]
    #   end
    #   
    #   if(!options[:activityaddress].nil?)
    #     returnparams[:activityaddress] = options[:activityaddress]
    #   end
    # 
    #   if(!options[:activityentrytype].nil?)
    #     returnparams[:activityentrytype] = options[:activityentrytype]
    #   end
    #   
    #   if(!options[:activity].nil?)
    #     returnparams[:activity] = options[:activity]
    #   end
    # 
    #   if(!options[:activitygroup].nil?)
    #     returnparams[:activitygroup] = options[:activitygroup]
    #   end
    # 
    #   if(!options[:ignorecommunity].nil?)
    #     returnparams[:ignorecommunity] = options[:ignorecommunity].id
    #   end
    # 
    #   if(!options[:communityactivity].nil?)
    #     returnparams[:communityactivity] = options[:communityactivity]
    #   end
    # 
    #   return returnparams
    # 
    # end
end
