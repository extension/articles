# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module DataImportCommon

  def execute_timestamp_sql(timestampsql,loglabel)
    connection = self.connection
    if(timestampsql.nil?)
      return false
    end
  
    logger.info "##################### Starting #{loglabel} timestamp retrieval..."
        
    # execute sql 
    begin
      result = connection.execute(timestampsql)
    rescue => err
      logger.error "ERROR: Exception raised during #{loglabel} timestamp retrieval: #{err}"
      return false
    end
  
    resulthash = result.fetch_hash
    begin 
       lastupdated = DateTime.parse(resulthash["last_updated_time"])
    rescue => err
      ActiveRecord::Base::logger.error "ERROR: Exception raised during #{loglabel} timestamp conversion: #{err}"
      return false
    end
  
    logger.info "##################### Finished #{loglabel} timestamp retrieval  (lastupdated: #{lastupdated.to_s})..."
  
    return lastupdated
  end

end