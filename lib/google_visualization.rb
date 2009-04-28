# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module GoogleVisualization

  def make_json_googledata_table(columns,values)
    data_table = {}

    data_table[:columns] = []
    columns.each do |columnhash|
        
      attribute = columnhash[:attribute]
      gdatatype = columnhash[:gdatatype]
      
      if(columnhash[:label].nil?)
        label = attribute.capitalize
      else
        label = columnhash[:label]
      end
      
      data_table[:columns] << {:attribute => attribute, :gdatatype => gdatatype, :label => label} 
    end
    
    data_table[:rows] = []
    values.each do |valueshash|
      rowrecord = []
      data_table[:columns].each do |columnhash|
        value = valueshash[columnhash[:attribute]]
        if(columnhash[:gdatatype] == 'string')
          rowrecord << value.to_s
        elsif(columnhash[:gdatatype] == 'number' and (value.is_a?(Float) or value.is_a?(Fixnum)))
          rowrecord << value
        elsif(columnhash[:gdatatype] == 'date' and (value.is_a?(Date) or value.is_a?(Time)))
          rowrecord << "new Date(#{value.year},#{value.month-1},#{value.mday})"
        elsif(columnhash[:gdatatype] == 'datetime' and value.is_a?(Time))
          rowrecord << "new Date(#{value.year},#{value.month-1},#{value.mday},#{value.hour},#{value.min},#{value.sec})"
        end
      end
      data_table[:rows] << rowrecord
    end
    
    return json_data_table(data_table)
  end

  # columns -> ordered array of hashes
  def get_json_googledata_table(columns,findoptions)
    data_table = {}
    
    column_type_hash = {
      :string => 'string',
      :integer => 'number',
      :float => 'number',
      :date => 'date',
      :datetime => 'datetime'
    }
    
    data_table[:columns] = []
    columns.each do |columnhash|
      if(!self.column_names.include?(columnhash[:attribute]))
        return nil
      end
      
      attribute = columnhash[:attribute]
      if(columnhash[:gdatatype].nil?)
        gdatatype = column_type_hash[self.columns_hash[attribute].type]
      else
        gdatatype = columnhash[:gdatatype]
      end
      
      if(columnhash[:label].nil?)
        label = attribute.capitalize
      else
        label = columnhash[:label]
      end
      
      data_table[:columns] << {:attribute => attribute, :gdatatype => gdatatype, :label => label} 
    end
    
    records = self.find(:all,findoptions)
    if(records.nil?)
      return nil
    end
    
    data_table[:rows] = []
    records.each do |record|
      rowrecord = []
      data_table[:columns].each do |columnhash|
        value = record.send(columnhash[:attribute])
        if(columnhash[:gdatatype] == 'string')
          rowrecord << value.to_s
        elsif(columnhash[:gdatatype] == 'number' and (value.is_a?(Float) or value.is_a?(Fixnum)))
          rowrecord << value
        elsif(columnhash[:gdatatype] == 'date' and (value.is_a?(Date) or value.is_a?(Time)))
          rowrecord << "new Date(#{value.year},#{value.month-1},#{value.mday})"
        elsif(columnhash[:gdatatype] == 'datetime' and value.is_a?(Time))
          rowrecord << "new Date(#{value.year},#{value.month-1},#{value.mday},#{value.hour},#{value.min},#{value.sec})"
        end
      end
      data_table[:rows] << rowrecord
    end
    
    # built the data_table, output the json string
    return json_data_table(data_table)
  end  
  
  def json_data_table(data_table)
    columnarray = []
    data_table[:columns].each do |columnhash|    
      columnarray << "{label: '#{columnhash[:label]}',type: '#{columnhash[:gdatatype]}'}"
    end
    
    rowarray = []
    data_table[:rows].each do |rowrecord|
      rowvalues = []
      rowrecord.each do |rowvalue|
        if(rowvalue.is_a?(String))
          if(/^new Date/ =~ rowvalue)
            rowvalues << "{v: #{rowvalue}}"
          else
            rowvalues << "{v: '#{rowvalue}'}"
          end
        else
          rowvalues << "{v: #{rowvalue}}"
        end
      end
      rowarray << "{c: [#{rowvalues.join(',')}]}"
    end
    
    json_output = "{"
    json_output += " cols: [#{columnarray.join(',')}],"
    json_output += " rows: [#{rowarray.join(',')}]"
    json_output += "}"
    
    return json_output
  end
  
end
