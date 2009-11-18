# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module ConditionExtensions

  def count_cache_expiry
    if(!AppConfig.configtable['cache-expiry'][self.name].nil?)
      AppConfig.configtable['cache-expiry'][self.name]
    else
      15.minutes
    end
  end
  
  def get_cache_key(method_name,optionshash={})
    optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
    cache_key = "#{self.name}::#{method_name}::#{optionshashval}"
    return cache_key
  end
  
  def build_association_condition(association,options={})
    symbol = association.to_sym
    pluralsymbol = association.pluralize.to_sym
    if(!(association = self.reflect_on_association(symbol)))
      return nil
    end
    
    columncompare = association.primary_key_name
    
    if(options[symbol])
      return "#{table_name}.#{columncompare} = #{options[symbol].id}"
    elsif(options[pluralsymbol])
      idlist = options[:pluralsymbol].map(&:id).join(',')
      return "#{table_name}.#{columncompare} IN #{idlist}"
    else
      return nil
    end
  end
  

  def build_date_condition(options={})
    # TODO:  other date shortcuts like "thisweek", etc.  
    datefield = options[:datefield] || AppConfig.configtable['default_datefield']
    dateinterval = options[:dateinterval] || AppConfig.configtable['default_dateinterval']
    tz = options[:tz] || AppConfig.configtable['default_timezone']  
    
    
    if(tz and tz != 'UTC' and TZInfo::Timezone.all_identifiers.include?(tz))
      datecolumn = "CONVERT_TZ(#{table_name}.#{datefield},'UTC','#{tz}')"
    else
      datecolumn = "#{table_name}.#{datefield}"
    end
    

    if(dateinterval.nil? or dateinterval == 'all')
      return nil
    end
    
    if(!self.column_names.include?(datefield))
      return nil
    end
    
    if(dateinterval.is_a?(Date))
      return "DATE(#{datecolumn}) = '#{dateinterval.to_s}'"
    end
    
    if(dateinterval.is_a?(Array))
      # range
      if(dateinterval[0].is_a?(Date))
        start_date = dateinterval[0]
      elsif(dateinterval[0].is_a?(String))
        begin
          start_date = Date.strptime(dateinterval[0])
        rescue
          return nil
        end
      end
      
      if(dateinterval[1].is_a?(Date))
        end_date = dateinterval[1]
      elsif(dateinterval[1].is_a?(String))
        begin
          end_date = Date.strptime(dateinterval[1])
        rescue
          return nil
        end
      end
      
      return "TRIM(DATE(#{datecolumn})) BETWEEN '#{start_date.to_s}' AND '#{end_date.to_s}'"
    end
    
    if(dateinterval.is_a?(String))
      # check for special values
      case dateinterval
      when 'today'
        return "DATE(#{datecolumn}) = CURDATE()"      
      when 'withinlastweek'
        return "#{datecolumn} > date_sub(curdate(), INTERVAL 1 WEEK)"
      when 'withinlastmonth'
        return "#{datecolumn} > date_sub(curdate(), INTERVAL 1 MONTH)"
      when 'withinlastyear'
        return "#{datecolumn} > date_sub(curdate(), INTERVAL 1 YEAR)"
      else
        if(/(\d+)\s+(day|week|month|year)s?/i =~ dateinterval)
          # N day|week|month|year
          return "#{datecolumn} > date_sub(curdate(), INTERVAL #{$1} #{$2.upcase})"
        elsif(/([\w-]+)\.\.([\w-]+)/ =~ dateinterval) # range
          # valid dates?
          begin
            start_date = Date.strptime($1)
            end_date = Date.strptime($2)
          rescue
            return nil
          end
          return "TRIM(DATE(#{datecolumn})) BETWEEN '#{start_date.to_s}' AND '#{end_date.to_s}'"
        else # date string?
          begin
            comparedate = Date.strptime(dateinterval)
          rescue
            return nil
          end
          return "DATE(#{datecolumn}) = '#{comparedate.to_s}'"
        end
      end
    end
    
    # unknown type for dateinterval
    return nil
  end
end