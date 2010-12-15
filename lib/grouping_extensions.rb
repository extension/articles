# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

include ConditionExtensions

module GroupingExtensions
  
  def userfilteredparameters
    filteredparams_list = []
    # list everything that userfilter_conditions handles
    # build_date_condition
    filteredparams_list += [:dateinterval,:datefield]
    # build_entrytype_condition
    filteredparams_list += [{:entrytype => :integer}]
    # community params 
    filteredparams_list += [:community,:communitytype,:connectiontype]
    # build_association_conditions
    filteredparams_list += [:institution,:location,:position, :county]
    # allusers
    filteredparams_list += [{:allusers => :boolean}]
    filteredparams_list
  end
  
  def build_entrytype_condition(options={})
    if(options[:entrytype])
      return "#{table_name}.entrytype = #{options[:entrytype]}"
    elsif(options[:entrytypes])
      return "#{table_name}.entrytype IN (#{options[:entrytypes].join(',')})"
    else
      return nil
    end
  end
  
  def userfilter_conditions(options={})
    if(options.nil?)
      options = {}
    end
    
    joins = []
    conditions = []
    
    conditions << build_date_condition(options)
    conditions << build_entrytype_condition(options)
    
    if(options[:community])
      joins << {:users => :communities}
      conditions << "#{Community.table_name}.id = #{options[:community].id}"
      conditions << "#{Communityconnection.connection_condition(options[:connectiontype])}"
    elsif(options[:communitytype])
      joins << {:users => :communities}
      conditions << "#{Community.communitytype_condition(options[:communitytype])}"
      conditions << "#{Communityconnection.connection_condition(options[:connectiontype])}"
    else
      joins << [:users]
    end
    
    # location, position, institution?
    conditions << User.build_association_conditions(options)
    
    if(options[:allusers].nil? or !options[:allusers])
      conditions << "#{User.table_name}.retired = 0 and #{User.table_name}.vouched = 1 and #{User.table_name}.id != 1"
    end      
    
    return {:joins => joins.compact, :conditions => conditions.compact.join(' AND ')}
  end
  
  def userfilter_count(options={},returnarray = false)
    countarray = self.filtered(options).count('accounts.id', :group => "#{table_name}.id")
    if(returnarray)
      return countarray
    else
      returnhash = {}
      countarray.map{|values| returnhash[values[0]] = values[1].to_i}
      return returnhash
    end
  end
  


end
