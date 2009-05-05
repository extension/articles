require 'csv'
require 'ar-extensions'

class ZipCode < ActiveRecord::Base
  def self.find_location_and_institution(zip_code)
    if(zip_code and zip_code != "")
      state_abb = to_state(zip_code.to_i)
      location = Location.find_by_abbreviation(state_abb)
      location_name = location.name
      institutions = location.institutions 
    end
    if !institutions || institutions.empty?
      state_abb = to_state(zip_code)
      location = Location.find_by_abbreviation(state_abb)
      institutions = Institution.find(:all)
      location_name = location.name
    end
    return location_name, institutions
  end
  
  def county
    return County.find_by_countycode_and_location_id(self.county_fips, self.location.id)
  end
  def location
    return Location.find_by_abbreviation(self.state)
  end 
  
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  
  class << self
      
    # --------------------------------------------------
    # Parsing, importing - borrows heavily from seymour
    # --------------------------------------------------
    
      @@csv_cols = [ :zip_code, :city, :state, :county, :area_code, :city_type, 
                      :city_alias_abbreviation, :city_alias_name, :latitude, :longitude, 
                      :time_zone, :elevation, :county_fips, :day_light_savings ]


    def import_zipcodes(file, purge = false)
      ZipCode.delete_all if purge
    
      # For performance reasons we're going to try and add in chunking here
      chunked_import(file, :zipcode) do |row_chunk|
        values = CSV::Reader.parse(row_chunk).collect {|row| zipcode_props_from_csv(row)}.compact
      
      
        # This is MySQL specific bulk-insert using ar-extensions...
        ZipCode.import @@csv_cols, values #, :ignore => true
      end
    end
   
    private
  
    # Perform standard chunked importing
    def chunked_import(file, type, chunk_size = 500)
      chunk_csv(file, chunk_size) do |row_chunk, index|
        transaction do
          self.benchmark("Importing chunked #{type} data, rows #{index * chunk_size} to #{index * chunk_size + chunk_size}", Logger::INFO) do
            yield row_chunk
          end
        end
      end
    end
  
    # Chunk a file into manageable bits suitable for passing into CSV::Reader.parse
    def chunk_csv(file, chunk_size)
      File.new(file, 'r').to_a.in_groups_of(chunk_size).each_with_index do |row_chunk, index|
        yield row_chunk.join("\n"), index
      end
    end  
  
    def zipcode_props_from_csv(row_vals)
      zip_code = row_vals[@@csv_cols.index(:zip_code)]
      properties_from(row_vals) if zip_code && zip_code.to_i > 0
    end 
    
    def properties_from(row_vals)
      @@csv_cols.collect { |name| row_vals[@@csv_cols.index(name)] }
    end 
  end
end