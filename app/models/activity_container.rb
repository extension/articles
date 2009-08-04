# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ActivityContainer
  include GoogleVisualization
  extend GoogleVisualization
  
  attr_accessor :findoptions, :forcecacheupdate, :datatype, :datalabel, :graphtype
  WEEKDAYS = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']
  
  def initialize(options = {})
    @data = {}
    self.findoptions = (options[:findoptions].nil? ? {} : options[:findoptions])
    self.datatype = (options[:datatype].nil? ? 'hourly' : options[:datatype])
    self.graphtype = (options[:graphtype].nil? ? 'area' : options[:graphtype])

    if(!options[:datalabel].nil?) 
      self.datalabel = options[:datalabel] 
    elsif(!self.findoptions[:datalabel].nil?)
      self.datalabel = self.findoptions[:datalabel]
    else
      self.datalabel = 'Activity'
    end
    self.forcecacheupdate = options[:forcecacheupdate].nil? ? false : options[:forcecacheupdate]  
  end
  
  def hourly
    Activity.hourlycount_with_userfilter(self.findoptions,self.forcecacheupdate)
  end
  
  def weekday
    Activity.weekdaycount_with_userfilter(self.findoptions,self.forcecacheupdate)
  end
  
  def weekofyear
    Activity.weekofyearcount_with_userfilter(self.findoptions,self.forcecacheupdate)
  end
  
  def monthofyear
    Activity.monthcount_with_userfilter(self.findoptions,self.forcecacheupdate)
  end
  
  def month
    Activity.yearmonthcount_with_userfilter(self.findoptions,self.forcecacheupdate)
  end
  
  def week
    Activity.yearweekcount_with_userfilter(self.findoptions,self.forcecacheupdate)
  end
  
  def date
    Activity.datecount_with_userfilter(self.findoptions,self.forcecacheupdate)
  end
  
  def table
    case self.datatype
    when 'hourly'
      titleattribute = 'activityhour'
      titlelabel = 'Hour'
    when 'weekday'
      titleattribute = 'activityweekday'
      titlelabel = 'Weekday'
    when 'weekofyear'
      titleattribute = 'activityweekofyear'
      titlelabel = 'Week of Year'
    when 'month'
      titleattribute = 'activitymonth'
      titlelabel = 'Month'
    when 'week'
      titleattribute = 'activityweek'
      titlelabel = 'Week'      
    when 'monthofyear'
      titleattribute = 'activitymonthofyear'
      titlelabel = 'Month of Year'
    when 'date'
      titleattribute = 'activitydate'
      titlelabel = 'Date'
    else
      return nil
    end
    
    if(self.graphtype == 'timeline')
      gdatatype = 'date'
    else
      gdatatype = 'string'
    end
      
    columns = [{:attribute => titleattribute, :gdatatype => gdatatype, :label => titlelabel}]
    columns << {:attribute => 'datacolumn', :gdatatype => 'number', :label => self.datalabel}

    counts = self.send(self.datatype)
    values = []
    first = counts.keys.sort.first
    last = counts.keys.sort.last
    if(self.datatype == 'week')
      rangevalues = self.class.convert_yearweek_to_array(first,last)
    elsif(self.datatype == 'month')
      rangevalues = self.class.convert_yearmonth_to_array(first,last)
    else
      # assumes range is enumerable by '1'
      rangevalues = (first..last)
    end
    
    rangevalues.each do |countvalue|      
      valueshash = {}
      if(self.datatype == 'weekday')
        valueshash[titleattribute] = WEEKDAYS[countvalue]
        valueshash['datacolumn'] = counts[countvalue].nil? ? 0 : counts[countvalue]
      else
        valueshash[titleattribute] = countvalue
        valueshash['datacolumn'] = counts[countvalue].nil? ? 0 : counts[countvalue]
      end
      values << valueshash      
    end    

    return self.make_json_googledata_table(columns,values)    
  end
  
  private
  

  
  def get_or_set_data_value(key)
    if(!@data[key].blank?)
      @data[key]
    elsif block_given?
      @data[key] = yield
      @data[key]
    else
      nil
    end
  end
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def convert_yearweek_to_array(first,last)
      returnarray = []
      currentweek = Date.strptime(first,'%Y-%W')
      lastweek = Date.strptime(last,'%Y-%W')
      while(currentweek <= lastweek)
        returnarray << currentweek.strftime("%Y-%W")
        currentweek += 1.week
      end
      return returnarray
    end
    
    def convert_yearmonth_to_array(first,last)
      returnarray = []
      currentmonth = Date.parse(first+'-01')
      lastmonth = Date.parse(last+'-01')
      while(currentmonth <= lastmonth)
        returnarray << currentmonth.strftime("%Y-%m")
        currentmonth += 1.month
      end
      return returnarray
    end
    
    def comparisontable(containers,normalize=false,normalize_to_value=100)
      columns = ['primary','secondary','tertiary','quaternary','quinary','senary','septenary']
      
      case containers[0].datatype
      when 'hourly'
        titleattribute = 'activityhour'
        titlelabel = 'Hour'
      when 'weekday'
        titleattribute = 'activityweekday'
        titlelabel = 'Weekday'
      when 'weekofyear'
        titleattribute = 'activityweekofyear'
        titlelabel = 'Week of Year'
      when 'month'
        titleattribute = 'activitymonth'
        titlelabel = 'Month'
      when 'week'
        titleattribute = 'activityweek'
        titlelabel = 'Week'      
      when 'monthofyear'
        titleattribute = 'activitymonthofyear'
        titlelabel = 'Month of Year'
      when 'date'
        titleattribute = 'activitydate'
        titlelabel = 'Date'
      else
        return nil
      end
      
      if(containers[0].graphtype == 'timeline')
        gdatatype = 'date'
      else
        gdatatype = 'string'
      end  
      
      columns = [{:attribute => titleattribute, :gdatatype => gdatatype, :label => titlelabel}]
      countsarray = []
      containers.each_with_index do |container,index|      
        columns << {:attribute => "#{columns[index]}", :gdatatype => 'number', :label => container.datalabel}
        countsarray[index] = container.send(container.datatype)
      end
      
      values = []
      # assumes range is enumerable by '1'
      # based off primary range! 
      first = countsarray[0].keys.sort.first
      last = countsarray[0].keys.sort.last
      if(containers[0].datatype == 'week')
        rangevalues = self.convert_yearweek_to_array(first,last)
      elsif(containers[0].datatype == 'month')
        rangevalues = self.convert_yearmonth_to_array(first,last)
      else
        # assumes range is enumerable by '1'
        rangevalues = (first..last)
      end
      rangevalues.each do |countvalue|
        valueshash = {}
        if(containers[0].datatype == 'weekday')
          valueshash[titleattribute] = WEEKDAYS[countvalue]
        else
          valueshash[titleattribute] = countvalue
        end
        containers.each_with_index do |container,index|                
          columnvalue = countsarray[index][countvalue].nil? ? 0 : countsarray[index][countvalue]        
          if(normalize)
            max = countsarray[index].values.max
            valueshash["#{columns[index]}"] = ((columnvalue/max.to_f)*normalize_to_value)
          else
            valueshash["#{columns[index]}"] = columnvalue
          end
        end
        values << valueshash      
      end
      
      return self.make_json_googledata_table(columns,values)    
    end
  
  end

end